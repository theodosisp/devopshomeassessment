output "deploy_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "Role ARN for GitHub Actions (configure AWS_ROLE_ARN in CI)."
}

output "oidc_provider_arn" {
  value       = local.github_oidc_provider_arn
  description = "GitHub OIDC provider ARN (existing or newly created)."
}
