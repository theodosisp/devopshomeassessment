# Security notes

Nothing fancy here — just how we actually wired things.

## IAM

ECS tasks use the normal execution role (`AmazonECSTaskExecutionRolePolicy`) so they can pull images and send logs. The task role is basically empty on purpose; once the app talks to AWS APIs we’d tighten that down instead of handing it `*` on day one.

For GitHub Actions we leaned on OIDC (`token.actions.githubusercontent.com`). Deploy roles only trust this repo’s subjects, and the policies stay narrow: ECR push/pull where needed, ECS describe/update, PassRole only for the execution + task roles Terraform created. If someone copies this stack, update the trust `sub` pattern so another fork doesn’t inherit access.

## Secrets

We’re not parking IAM user keys in GitHub Secrets for the pipelines described here — just the role ARNs and OIDC doing the rest.

Anything application-level later belongs in Secrets Manager (or SSM Parameter Store if you prefer) and gets wired through the task definition. Nothing sensitive lives in the repo.

## Images

CI runs Trivy with HIGH/CRITICAL as hard failures. ECR also scans on push because Terraform enabled it on the repos — redundant but I’d rather get yelled at twice than ship something obviously broken.

## TLS / HTTP

CloudFront forces HTTPS at the edge for the static stuff.

The ALB path is still HTTP on port 80 in this repo — it was faster to stand up for the exercise. Real prod hardening would be ACM on the ALB, HTTPS listener, redirect 80→443. Leaving this note so nobody assumes “we’re done” just because CloudFront is locked down.

## WAF

Prod CloudFront sits behind the usual AWS managed bundles (`CommonRuleSet`, `KnownBadInputs`). If we ever carve out a noisy rule, document it here — future me won’t remember why we excluded something.

Staging doesn’t run WAF. Cheaper, faster iterations, and honestly lower stakes — but the URL *can* still get probed, so don’t treat staging like a vault.
