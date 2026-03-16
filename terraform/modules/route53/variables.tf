variable "zone_id" {
  description = "Hosted zone ID where the alias record will be created."
  type        = string
}

variable "record_name" {
  description = "DNS record name (for example: api.bookvault.example.com)."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name used as Route53 alias target."
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID used as Route53 alias target zone id."
  type        = string
}

variable "evaluate_target_health" {
  description = "Whether to evaluate target health for alias target."
  type        = bool
  default     = true
}
