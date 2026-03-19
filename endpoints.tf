resource "aws_security_group" "ssm_endpoints" {
  name        = "${var.project_name}-ssm-endpoints-sg"
  description = "Security group for private AWS API interface endpoints"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name      = "${var.project_name}-ssm-endpoints-sg"
    Terraform = "true"
    Project   = var.project_name
    Role      = "ssm-endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssm_endpoints_https_from_app" {
  security_group_id            = aws_security_group.ssm_endpoints.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS from app instances to private AWS API endpoints"
}

resource "aws_vpc_security_group_egress_rule" "ssm_endpoints_all_outbound" {
  security_group_id = aws_security_group.ssm_endpoints.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow endpoint response traffic"
}

locals {
  interface_endpoints = {
    ssm            = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages    = "com.amazonaws.${var.aws_region}.ssmmessages"
    ec2messages    = "com.amazonaws.${var.aws_region}.ec2messages"
    logs           = "com.amazonaws.${var.aws_region}.logs"
    secretsmanager = "com.amazonaws.${var.aws_region}.secretsmanager"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = local.interface_endpoints

  vpc_id              = module.vpc.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = slice(module.vpc.private_subnets, 0, 2)
  security_group_ids  = [aws_security_group.ssm_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.project_name}-${each.key}-endpoint"
    Terraform = "true"
    Project   = var.project_name
    Role      = "ssm-endpoint"
  }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name      = "${var.project_name}-s3-endpoint"
    Terraform = "true"
    Project   = var.project_name
    Role      = "s3-endpoint"
  }
}