variable "name" {
  description = "Base name for ECS resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region for logs configuration."
  type        = string
}

variable "vpc_id" {
  description = "VPC where ECS service runs."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Fargate tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group allowed to reach ECS tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN used by ECS service."
  type        = string
}

variable "image" {
  description = "Container image to run (ECR URL plus tag)."
  type        = string
}

variable "container_name" {
  description = "Container name in task definition."
  type        = string
  default     = "bookvault-api"
}

variable "container_port" {
  description = "Container listening port."
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Desired number of running ECS tasks."
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB."
  type        = number
  default     = 512
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period."
  type        = number
  default     = 14
}

variable "environment_variables" {
  description = "Environment variables passed to the container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets injected into the container from AWS Secrets Manager."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "secrets_access_arns" {
  description = "Secret ARNs the ECS task execution role can read."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}
