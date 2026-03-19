resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Security group for the application Redis cache"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name      = "${var.project_name}-redis-sg"
    Terraform = "true"
    Project   = var.project_name
    Role      = "redis"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  description                  = "Allow Redis access from backend application instances"
}

resource "random_password" "redis_auth_token" {
  length  = var.redis_auth_token_length
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth_token" {
  name                    = "${var.project_name}/redis/auth-token"
  description             = "Redis auth token for ${var.project_name} backend instances"
  recovery_window_in_days = 0

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "redis-secret"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
  })
}

module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.11.0"

  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cache for ${var.project_name} application"

  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type
  port           = var.redis_port

  create_replication_group = true
  create_security_group    = false
  create_subnet_group      = true
  subnet_ids               = slice(module.vpc.private_subnets, 0, 2)
  security_group_ids       = [aws_security_group.redis.id]

  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_num_cache_clusters > 1
  multi_az_enabled           = var.redis_num_cache_clusters > 1

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  apply_immediately          = true
  auto_minor_version_upgrade = true
  snapshot_retention_limit   = 1
  log_delivery_configuration = {
    slow-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
  }

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "redis"
  }

  depends_on = [aws_secretsmanager_secret_version.redis_auth_token]
}