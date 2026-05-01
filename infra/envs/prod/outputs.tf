output "alb_dns_name" {
  value       = module.ecs_api.alb_dns_name
  description = "ALB DNS — HTTP :80 (use for /healthz checks in Part 4)."
}

output "cloudfront_domain_name" {
  value       = module.cdn.cloudfront_domain_name
  description = "CloudFront hostname for static site."
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "docker push target for prod images."
}

output "github_deploy_role_arn_prod" {
  value       = module.iam_github.deploy_role_arn
  description = "GitHub Actions OIDC deploy role for prod."
}

output "ecs_cluster_name" {
  value       = module.ecs_api.cluster_name
}

output "ecs_service_name" {
  value       = module.ecs_api.service_name
}

output "ecs_task_definition_family" {
  value       = module.ecs_api.task_definition_family
}

output "rds_identifier_stub" {
  value       = var.rds_identifier_stub
  description = "STUB — no RDS instance exists."
}
