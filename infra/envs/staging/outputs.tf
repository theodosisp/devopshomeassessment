output "alb_dns_name" {
  value       = module.ecs_api.alb_dns_name
  description = "Staging ALB DNS — HTTP :80."
}

output "cloudfront_domain_name" {
  value       = module.cdn.cloudfront_domain_name
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
}

output "github_deploy_role_arn_staging" {
  value       = module.iam_github.deploy_role_arn
  description = "GitHub Actions OIDC deploy role for staging (OIDC provider created in prod apply)."
}

output "rds_identifier_stub" {
  value       = var.rds_identifier_stub
  description = "STUB — no RDS instance exists."
}
