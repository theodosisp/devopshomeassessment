# Security baseline

This document matches assessment Part 5 expectations and how this repository implements them.

## IAM least privilege

- **Runtime**: ECS task execution role uses AWS managed **AmazonECSTaskExecutionRolePolicy** (pull from ECR, write logs). Task role is minimal (extend when app needs AWS APIs).
- **Deploy**: GitHub Actions assumes environment-scoped IAM roles via **OIDC** (`token.actions.githubusercontent.com`). Trust policy restricts `sub` to this repository. Policies scope **ECR** and **ECS** to the environment’s resources and allow **`iam:PassRole`** only for the known execution/task roles.

## Secrets

- **No long-lived AWS access keys** in GitHub for CI/CD paths described here — use **`AWS_ROLE_ARN_STAGING`** / **`AWS_ROLE_ARN_PROD`** secrets with OIDC.
- Application secrets (future): store in **AWS Secrets Manager**, inject via task definition `secrets` block — **not** committed to Git.

## Container scanning

- **Trivy** runs in `.github/workflows/ci.yml` with **`HIGH,CRITICAL`** failing the build (`exit-code 1`).
- **ECR**: scan-on-push enabled on repositories created by Terraform.

## Encryption and HTTPS

- **CloudFront**: viewer protocol **redirect-to-https**; default TLS at edge for static delivery.
- **ALB (API)**: bootstrap uses **HTTP :80** for speed of setup; production hardening adds **ACM certificate + HTTPS listener** and redirects HTTP→HTTPS at ALB (recommended next step).

## CDN / edge hardening

- **Production** CloudFront is associated with **AWS WAF** managed rule groups (`AWSManagedRulesCommonRuleSet`, `AWSManagedRulesKnownBadInputsRuleSet`). Document exclusions here if any rule is tuned later:

  - *Current exclusions*: none (stub).

## Staging risk acceptance

- **No WAF** on staging CloudFront — documented tradeoff in README (cost/velocity vs abuse risk).
