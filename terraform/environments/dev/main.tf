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
  tags                  = local.common_tags
}
