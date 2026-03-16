variable "name" {
  description = "Base name for ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB and target group are created."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement."
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by ECS tasks."
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "ALB target group health check path."
  type        = string
  default     = "/health"
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
