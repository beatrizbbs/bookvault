output "alb_dns_name" {
  description = "Public DNS name for API access through ALB."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL where API image is stored."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "route53_record_fqdn" {
  description = "Route53 alias record FQDN when enabled."
  value       = var.enable_route53 ? module.route53[0].fqdn : null
}

output "app_secret_arn" {
  description = "Managed app secret ARN when creation is enabled."
  value       = var.create_app_secret ? module.app_secret[0].secret_arn : null
}
