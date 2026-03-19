resource "random_password" "blog_admin_password" {
  length  = 24
  special = false
}

resource "random_password" "blog_token_secret" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "blog_admin" {
  name                    = "${var.project_name}/app/blog-admin"
  description             = "Admin authentication secret for the ${var.project_name} blog application"
  recovery_window_in_days = 0

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "blog-admin"
  }
}

resource "aws_secretsmanager_secret_version" "blog_admin" {
  secret_id = aws_secretsmanager_secret.blog_admin.id
  secret_string = jsonencode({
    username     = "admin"
    password     = random_password.blog_admin_password.result
    token_secret = random_password.blog_token_secret.result
  })
}