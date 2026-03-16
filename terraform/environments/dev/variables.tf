variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
  default     = "bookvault"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "AZs for public/private subnet pairs."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ecr_repository_name" {
  description = "ECR repository name for API image."
  type        = string
  default     = "bookvault-api"
}

variable "container_image_tag" {
  description = "Image tag to run in ECS."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Container and target group port."
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Desired ECS task count."
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "create_app_secret" {
  description = "Create a managed secret in Secrets Manager for the application."
  type        = bool
  default     = false
}

variable "app_secret_name" {
  description = "Name of the application secret in Secrets Manager."
  type        = string
  default     = "bookvault/dev/google-books-api-key"
}

variable "app_secret_description" {
  description = "Description for the managed application secret."
  type        = string
  default     = "Google Books API key for BookVault (dev)"
}

variable "app_secret_value" {
  description = "Optional value used for initial secret version."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "inject_app_secret" {
  description = "Inject the managed secret ARN into ECS container secrets."
  type        = bool
  default     = true
}

variable "app_secret_env_name" {
  description = "Container environment variable name for the managed secret."
  type        = string
  default     = "GOOGLE_BOOKS_API_KEY"
}

variable "enable_route53" {
  description = "Create a Route53 alias record pointing to the ALB."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used for record creation."
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "DNS record name for the ALB alias."
  type        = string
  default     = ""
}

variable "container_secrets" {
  description = "Secrets injected into the container from Secrets Manager."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "secrets_access_arns" {
  description = "Secret ARNs readable by the ECS task execution role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}
