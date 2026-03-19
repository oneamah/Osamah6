resource "aws_iam_policy" "app_runtime" {
  name        = "${var.project_name}-app-runtime"
  description = "Allow backend application instances to read runtime secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.db.db_instance_master_user_secret_arn,
          aws_secretsmanager_secret.redis_auth_token.arn,
          aws_secretsmanager_secret.app_source.arn,
          aws_secretsmanager_secret.blog_admin.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.media.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.media.arn}/*"
      }
    ]
  })

  tags = {
    Terraform = "true"
    Project   = var.project_name
    Role      = "app-runtime"
  }
}