# Security

## IAM

ECS tasks use the standard execution role (`AmazonECSTaskExecutionRolePolicy`) for pulling images and writing logs. The task role is intentionally minimal until the application requires AWS API access; extend it with scoped policies rather than broad permissions.

GitHub Actions uses OIDC (`token.actions.githubusercontent.com`). Deploy roles trust only subjects for this repository. Policies limit ECR and ECS actions to what deployment needs and allow `iam:PassRole` only for the execution and task roles created by Terraform. If you fork or reuse this configuration, update the trust policy `sub` pattern accordingly.

## Secrets

CI/CD uses IAM role ARNs with OIDC rather than long-lived IAM user access keys stored in GitHub.

Application secrets should live in AWS Secrets Manager or Parameter Store and be referenced from the task definition. Do not commit secrets to the repository.

## Container images

CI runs Trivy with HIGH and CRITICAL severities failing the build. ECR repositories created by Terraform have image scanning on push enabled.

## TLS

CloudFront is configured to redirect HTTP to HTTPS for static content.

The Application Load Balancer currently exposes HTTP on port 80 for the bootstrap setup. Production hardening should add an ACM certificate, an HTTPS listener, and redirect HTTP to HTTPS on the ALB.

## WAF

Production CloudFront is associated with AWS managed rule groups (`AWSManagedRulesCommonRuleSet`, `AWSManagedRulesKnownBadInputsRuleSet`). Document any rule exclusions or overrides here for future reference.

Staging does not use WAF in order to reduce cost and iteration friction. Staging endpoints should not be treated as equivalent to production from a security perspective.
