output "alb_arn" {
  description = "ALB ARN."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB."
  value       = aws_lb.this.zone_id
}

output "listener_arn" {
  description = "HTTP listener ARN."
  value       = aws_lb_listener.http.arn
}

output "target_group_arn" {
  description = "Target group ARN for ECS service attachment."
  value       = aws_lb_target_group.this.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = aws_security_group.alb.id
}
