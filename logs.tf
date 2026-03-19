resource "aws_cloudwatch_log_group" "app_backend" {
  name              = "/aws/ec2/${var.project_name}/backend"
  retention_in_days = var.app_log_retention_days

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "app-logs"
  }
}