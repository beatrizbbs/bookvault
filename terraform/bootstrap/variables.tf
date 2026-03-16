variable "aws_region" {
  description = "AWS region for backend resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix used for resource names."
  type        = string
  default     = "bookvault"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to backend resources."
  type        = map(string)
  default     = {}
}
