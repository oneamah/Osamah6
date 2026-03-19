data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  app_dir      = "/opt/${var.project_name}"
  app_log_file = "/var/log/${var.project_name}/app.log"
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application instances behind the ALB"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name      = "${var.project_name}-app-sg"
    Terraform = "true"
    Project   = var.project_name
    Role      = "app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP traffic from the ALB"
}

resource "aws_vpc_security_group_egress_rule" "app_https_to_interface_endpoints" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.ssm_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow outbound HTTPS traffic to private AWS API interface endpoints"
}

resource "aws_vpc_security_group_egress_rule" "app_https_to_s3" {
  security_group_id = aws_security_group.app.id
  prefix_list_id    = data.aws_prefix_list.s3.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTPS traffic to Amazon S3 through the gateway endpoint"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow backend application instances to connect to the RDS database"
}

resource "aws_vpc_security_group_egress_rule" "app_to_redis" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  description                  = "Allow backend application instances to connect to Redis"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnets            = slice(module.vpc.public_subnets, 0, 2)

  security_group_name        = "${var.project_name}-alb-sg"
  security_group_description = "Security group for the public application load balancer"
  security_group_ingress_rules = {
    http_ipv4 = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP from the internet"
    }
    https_ipv4 = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS from the internet"
    }
  }
  security_group_egress_rules = {
    to_app = {
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      referenced_security_group_id = aws_security_group.app.id
      description                  = "Allow HTTP traffic to app instances"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.tls_certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name_prefix       = "app"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      vpc_id            = module.vpc.vpc_id
      create_attachment = false
      health_check = {
        enabled             = true
        path                = var.alb_health_check_path
        protocol            = "HTTP"
        matcher             = var.alb_health_check_matcher
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "alb"
  }
}

module "app_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.2.0"

  name = "${var.project_name}-app"

  min_size                = var.asg_min_size
  desired_capacity        = var.asg_desired_capacity
  max_size                = var.asg_max_size
  default_instance_warmup = var.asg_default_instance_warmup

  health_check_type         = "ELB"
  health_check_grace_period = 300
  wait_for_elb_capacity     = var.asg_desired_capacity
  vpc_zone_identifier       = slice(module.vpc.private_subnets, 0, 2)

  image_id                    = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type               = var.public_instance_type
  create_iam_instance_profile = true
  iam_role_name               = "${var.project_name}-app-ssm-role"
  iam_role_description        = "IAM role for private app instances managed through AWS Systems Manager"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    AppRuntimePolicy             = aws_iam_policy.app_runtime.arn
  }

  security_groups = [aws_security_group.app.id]
  metadata_options = {
    http_tokens = "required"
  }
  user_data = base64encode(templatefile("${path.module}/templates/backend-bootstrap.sh.tftpl", {
    project_name   = var.project_name
    app_dir        = local.app_dir
    app_log_file   = local.app_log_file
    backend_app_secret_arn = aws_secretsmanager_secret.app_source.arn
    app_env        = <<-ENV
APP_NAME=${var.project_name}
APP_PORT=80
AWS_REGION=${var.aws_region}
DB_HOST=${module.db.db_instance_address}
DB_PORT=${module.db.db_instance_port}
DB_NAME=${var.db_name}
DB_USERNAME=${var.db_username}
DB_SECRET_ARN=${module.db.db_instance_master_user_secret_arn}
AUTH_SECRET_ARN=${aws_secretsmanager_secret.blog_admin.arn}
MEDIA_BUCKET_NAME=${aws_s3_bucket.media.bucket}
MEDIA_BASE_URL=${local.media_base_url}
MEDIA_UPLOAD_MAX_BYTES=${var.media_upload_max_bytes}
REDIS_HOST=${module.redis.replication_group_primary_endpoint_address}
REDIS_PORT=${module.redis.replication_group_port}
REDIS_TLS_ENABLED=true
REDIS_AUTH_TOKEN_SECRET_ARN=${aws_secretsmanager_secret.redis_auth_token.arn}
APP_SECRET_REFRESH_INTERVAL_SECONDS=${var.app_secret_refresh_interval_seconds}
APP_LOG_LEVEL=INFO
APP_SOURCE_VERSION=${aws_secretsmanager_secret_version.app_source.version_id}
ENV
    cwagent_config = templatefile("${path.module}/templates/cloudwatch-agent.json.tftpl", {
      aws_region        = var.aws_region
      app_log_file      = local.app_log_file
      log_group_name    = aws_cloudwatch_log_group.app_backend.name
      retention_in_days = var.app_log_retention_days
    })
  }))

  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = module.alb.target_groups.app.arn
      traffic_source_type       = "elbv2"
    }
  }

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = var.asg_default_instance_warmup
    }
  }

  scaling_policies = {
    cpu_target_tracking = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = var.asg_default_instance_warmup
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = var.asg_cpu_target_utilization
      }
    }
  }

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "app-asg-private"
  }
}