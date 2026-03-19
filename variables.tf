variable "aws_region" {
  description = "AWS region used by the AWS provider. Set this locally or in HCP Terraform workspace variables."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used to tag and name shared infrastructure resources."
  type        = string
  default     = "marmil"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use for the VPC subnets."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 to place the ALB and application instances across two public subnets."
  }
}

variable "public_instance_type" {
  description = "Instance type for the Auto Scaling Group instances."
  type        = string
  default     = "t3.micro"
}

variable "app_log_retention_days" {
  description = "Retention in days for backend application logs shipped to CloudWatch Logs."
  type        = number
  default     = 14
}

variable "app_secret_refresh_interval_seconds" {
  description = "How often the backend process refreshes runtime secrets from Secrets Manager."
  type        = number
  default     = 300
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN to use for the ALB HTTPS listener. If null, Terraform creates and validates a certificate in ACM."
  type        = string
  default     = null
}

variable "acm_domain_name" {
  description = "Primary DNS name for the managed ACM certificate and public application endpoint."
  type        = string
  default     = "marmil.co"
}

variable "acm_subject_alternative_names" {
  description = "Optional subject alternative names to include in the managed ACM certificate."
  type        = list(string)
  default     = ["*.marmil.co"]
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID where the ALB alias record will be created."
  type        = string
  default     = "XXXXXXXXX"
}

variable "route53_record_name" {
  description = "DNS record name to create for the HTTPS ALB, for example app.example.com."
  type        = string
  default     = "marmil.co"
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "asg_default_instance_warmup" {
  description = "Time in seconds for a newly launched Auto Scaling Group instance to warm up before contributing metrics."
  type        = number
  default     = 300
}

variable "asg_cpu_target_utilization" {
  description = "Target average CPU utilization percentage for Auto Scaling target tracking."
  type        = number
  default     = 60
}

variable "alb_health_check_path" {
  description = "Health check path used by the ALB target group."
  type        = string
  default     = "/"
}

variable "alb_health_check_matcher" {
  description = "Expected HTTP response codes for ALB health checks."
  type        = string
  default     = "200"
}

variable "db_name" {
  description = "Initial database name for the application RDS instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the application RDS instance."
  type        = string
  default     = "appadmin"
}

variable "db_engine" {
  description = "Database engine for the application RDS instance."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version for the application RDS instance."
  type        = string
  default     = "16"
}

variable "db_family" {
  description = "Parameter group family for the application RDS instance."
  type        = string
  default     = "postgres16"
}

variable "db_major_engine_version" {
  description = "Major engine version for the application RDS option group."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "Instance class for the application RDS instance."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB for the application RDS instance."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB for the application RDS instance."
  type        = number
  default     = 100
}

variable "db_port" {
  description = "Port used by the application RDS instance."
  type        = number
  default     = 5432
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups for the application RDS instance."
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Whether the application RDS instance should be deployed Multi-AZ."
  type        = bool
  default     = false
}

variable "redis_engine_version" {
  description = "Engine version for the ElastiCache Redis replication group."
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "Node type for the ElastiCache Redis replication group."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_port" {
  description = "Port used by the ElastiCache Redis replication group."
  type        = number
  default     = 6379
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters in the Redis replication group."
  type        = number
  default     = 1
}

variable "redis_auth_token_length" {
  description = "Length of the generated Redis auth token stored in Secrets Manager."
  type        = number
  default     = 32
}

variable "media_bucket_name" {
  description = "Optional custom name for the public S3 bucket that stores uploaded blog media."
  type        = string
  default     = null
}

variable "media_bucket_force_destroy" {
  description = "Whether Terraform may delete the blog media bucket even when it still contains uploaded objects."
  type        = bool
  default     = false
}

variable "media_upload_max_bytes" {
  description = "Maximum image upload size in bytes accepted by the admin media upload API."
  type        = number
  default     = 5242880
}