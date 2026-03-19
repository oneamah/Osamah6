resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for the application RDS instance"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name      = "${var.project_name}-db-sg"
    Terraform = "true"
    Project   = var.project_name
    Role      = "db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow database access from backend application instances"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.1.0"

  identifier = "${var.project_name}-db"

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  family               = var.db_family
  major_engine_version = var.db_major_engine_version
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  manage_master_user_password = true

  multi_az                = var.db_multi_az
  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = var.db_backup_retention_period

  create_db_subnet_group = true
  subnet_ids             = slice(module.vpc.private_subnets, 0, 2)
  vpc_security_group_ids = [aws_security_group.db.id]

  create_db_parameter_group = true
  create_db_option_group    = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "db"
  }
}