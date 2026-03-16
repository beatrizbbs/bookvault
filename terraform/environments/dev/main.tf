locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  managed_app_secret_arn = try(module.app_secret[0].secret_arn, null)

  ecs_container_secrets = local.managed_app_secret_arn != null && var.inject_app_secret ? concat(
    var.container_secrets,
    [
      {
        name       = var.app_secret_env_name
        value_from = local.managed_app_secret_arn
      }
    ]
  ) : var.container_secrets

  ecs_secrets_access_arns = local.managed_app_secret_arn != null && var.inject_app_secret ? distinct(
    concat(var.secrets_access_arns, [local.managed_app_secret_arn])
  ) : var.secrets_access_arns
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name = var.ecr_repository_name
  tags = local.common_tags
}

module "app_secret" {
  count  = var.create_app_secret ? 1 : 0
  source = "../../modules/secrets_manager"

  name        = var.app_secret_name
  description = var.app_secret_description
  secret_value = var.app_secret_value
  tags        = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  container_port     = var.container_port
  health_check_path  = "/health"
  tags               = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name                  = local.name_prefix
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  image                 = "${module.ecr.repository_url}:${var.container_image_tag}"
  container_name        = "bookvault-api"
  container_port        = var.container_port
  desired_count         = var.desired_count
  cpu                   = var.task_cpu
  memory                = var.task_memory
  secrets               = local.ecs_container_secrets
  secrets_access_arns   = local.ecs_secrets_access_arns
  tags                  = local.common_tags
}

module "route53" {
  count  = var.enable_route53 ? 1 : 0
  source = "../../modules/route53"

  zone_id     = var.route53_zone_id
  record_name = var.route53_record_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id = module.alb.alb_zone_id
}
