output "vpc_id" {
  description = "ID of the VPC created by the module."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets created by the module."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets created by the module."
  value       = module.vpc.private_subnets
}

output "alb_dns_name" {
  description = "DNS name of the public Application Load Balancer."
  value       = module.alb.dns_name
}

output "alb_https_url" {
  description = "HTTPS URL of the public Application Load Balancer."
  value       = "https://${aws_route53_record.alb_alias.fqdn}"
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used by the public Application Load Balancer."
  value       = local.tls_certificate_arn
}

output "route53_record_fqdn" {
  description = "Route 53 DNS name created for the HTTPS ALB."
  value       = aws_route53_record.alb_alias.fqdn
}

output "alb_security_group_id" {
  description = "Security group ID of the public Application Load Balancer."
  value       = module.alb.security_group_id
}

output "app_security_group_id" {
  description = "Security group ID attached to the Auto Scaling Group instances."
  value       = aws_security_group.app.id
}

output "db_endpoint" {
  description = "Endpoint of the application RDS instance."
  value       = module.db.db_instance_endpoint
}

output "db_address" {
  description = "Address of the application RDS instance."
  value       = module.db.db_instance_address
}

output "db_port" {
  description = "Port of the application RDS instance."
  value       = module.db.db_instance_port
}

output "db_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS master user secret."
  value       = module.db.db_instance_master_user_secret_arn
}

output "app_log_group_name" {
  description = "CloudWatch Logs log group used by the backend application instances."
  value       = aws_cloudwatch_log_group.app_backend.name
}

output "redis_primary_endpoint" {
  description = "Primary endpoint address of the application Redis replication group."
  value       = module.redis.replication_group_primary_endpoint_address
}

output "redis_port" {
  description = "Port of the application Redis replication group."
  value       = module.redis.replication_group_port
}

output "redis_auth_token_secret_arn" {
  description = "Secrets Manager ARN storing the Redis auth token."
  value       = aws_secretsmanager_secret.redis_auth_token.arn
}

output "blog_admin_secret_arn" {
  description = "Secrets Manager ARN storing the blog admin credentials and token secret."
  value       = aws_secretsmanager_secret.blog_admin.arn
}

output "media_bucket_name" {
  description = "Name of the public S3 bucket used for uploaded blog media assets."
  value       = aws_s3_bucket.media.bucket
}

output "media_base_url" {
  description = "Base URL for public blog media objects stored in S3."
  value       = local.media_base_url
}