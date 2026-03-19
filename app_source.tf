resource "aws_secretsmanager_secret" "app_source" {
  name                    = "${var.project_name}/app/source"
  description             = "Backend application source for ${var.project_name} instances"
  recovery_window_in_days = 0

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "app-source"
  }
}

resource "aws_secretsmanager_secret_version" "app_source" {
  secret_id     = aws_secretsmanager_secret.app_source.id
  secret_string = base64gzip(templatefile("${path.module}/templates/blog-app.py.tftpl", {}))
}