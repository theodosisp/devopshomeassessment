locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  tags        = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
  tags            = local.common_tags
}

module "cdn" {
  source = "../../modules/cdn"

  bucket_name = var.static_site_bucket_name
  tags        = local.common_tags
}

module "ecs_api" {
  source = "../../modules/ecs_alb_fargate"

  name_prefix        = local.name_prefix
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  container_port       = 80
  task_cpu             = var.task_cpu
  task_memory          = var.task_memory
  desired_count        = 1
  container_image      = var.bootstrap_container_image
  health_check_path    = var.health_check_path
  log_retention_days  = 3
  tags = merge(local.common_tags, {
    Project = var.project
  })
}

module "iam_github" {
  source = "../../modules/iam_github_oidc"

  name_prefix          = local.name_prefix
  create_oidc_provider = false
  github_org           = var.github_org
  github_repo          = var.github_repo
  ecr_repository_arn   = module.ecr.repository_arn
  ecs_cluster_arn      = module.ecs_api.cluster_arn
  ecs_service_arn      = module.ecs_api.service_arn
  execution_role_arn   = module.ecs_api.execution_role_arn
  task_role_arn        = module.ecs_api.task_role_arn
  tags                 = local.common_tags
}
