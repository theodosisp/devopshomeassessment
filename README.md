# DevOps Home Assessment (v4.4)

This repository contains Terraform for **Part 1** (CDN module) and **Part 2** (staging + production on AWS), plus submission artifacts. CI workflows and app code follow in later parts.

## Layout

- `infra/modules/cdn` — S3 + CloudFront (OAC, private bucket, HTTPS redirect) + Part 1 bug notes
- `infra/modules/network` — Isolated VPC (2 AZs, public + private subnets, single NAT)
- `infra/modules/ecr` — Container registry with scan-on-push
- `infra/modules/ecs_alb_fargate` — ALB + ECS Fargate (443 not configured — HTTP :80 for bootstrap; swap image in Part 4)
- `infra/modules/waf_cloudfront` — WAFv2 **CLOUDFRONT** scope (must use **us-east-1** provider in root module)
- `infra/modules/iam_github_oidc` — GitHub Actions deploy role (ECR + ECS + `iam:PassRole`)
- `infra/envs/part1` — Standalone test of the CDN module
- `infra/envs/prod` — Full prod stack (includes WAF on CloudFront + creates GitHub **OIDC provider** once per account)
- `infra/envs/staging` — Mirrored at smaller Fargate size; **no WAF**; reuses existing OIDC provider
- `submission/` — e.g. Part 1 plan output

## Remote state (required for Part 2)

Create an S3 bucket and DynamoDB table for locks (one-time per account/region), then point `backend.hcl` at them.

**Example (replace names):**

```bash
aws s3api create-bucket --bucket yourname-terraform-state-eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-bucket-versioning --bucket yourname-terraform-state-eu-central-1 --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

Copy `infra/envs/prod/backend.hcl.example` → `backend.hcl` and the same for staging (different `key`).

**Local / validation without remote state:** `terraform init -backend=false`

## Apply order (important)

1. **Prod** first — creates the **GitHub OIDC provider** (one per AWS account) and the **prod** deploy role.
2. **Staging** second — uses `create_oidc_provider = false` and looks up the existing provider. If you run staging first, `terraform apply` **fails** until prod has created the provider.

## Commands

**Prod** (from repo root, after `cp terraform.tfvars.example terraform.tfvars` and editing values):

```bash
cd infra/envs/prod
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

**Staging:**

```bash
cd infra/envs/staging
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

**Part 1 only:**

```bash
cd infra/envs/part1
terraform init
terraform plan -out=tfplan
```

After apply, read outputs (ALB DNS, ECR URL, deploy role ARNs) with `terraform output`.

## How CI artifacts flow into deploy (preview for Parts 4–5)

1. **GitHub Actions** builds a container image and tags it with **git SHA** (and optionally SemVer).
2. **OIDC** — workflow assumes **`AWS_ROLE_ARN`** for **staging** or **prod** (`terraform output` deploy roles). No long-lived AWS keys in GitHub.
3. **ECR** — `docker push` to the environment’s repository URL from outputs.
4. **ECS** — pipeline registers a new task definition revision (container image = pushed digest/tag) and calls **`ecs:UpdateService`**. This repo sets **`lifecycle { ignore_changes = [task_definition] }`** on the ECS service so Terraform **does not fight** CI-driven task definition updates after bootstrap.

The **`rds_identifier_stub`** variables are **documentation-only stubs** — no RDS resources are created here.

## Key decisions (tradeoffs)

1. **ECS Fargate + ALB vs EC2** — Chose **Fargate** for minimal ops (no AMI patching/ASG wiring) at the cost of slightly higher unit price vs rightsized EC2. Faster to ship for an assessment; EC2 would win if we needed **always-on GPUs**, **custom kernels**, or **long-lived SSH debugging**.

2. **Isolation: separate VPCs vs second AWS account** — Implemented **two VPCs in one account** (`10.10.0.0/16` staging, `10.20.0.0/16` prod). Tradeoff: **simpler IAM/billing** and one OIDC provider, but **less blast-radius separation** than a second account (Organization SCPs, separate billing alarms). A second account would be next step for production governance.

3. **Separate ECR repos for staging and prod** — Tradeoff: slightly more registry overhead vs **one shared repo + tags only**. Separate repos reduce risk of **wrong-tag prod push** and simplify lifecycle policies per environment.

4. **WAF only in prod** — Staging skips WAF to save cost and reduce friction for iterative testing. **Risk:** staging URLs can be abused for vulnerability scanning or accidental exposure of prerelease features; mitigations include **IP allowlists**, **auth**, or **short-lived staging environments**.

5. **Single NAT Gateway** — Keeps cost down; tradeoff is **AZ redundancy** for outbound traffic (NAT is a single path). Production hardening might use **NAT per AZ**.

6. **GitHub OIDC provider created once in prod** — AWS allows **one URL** per account for `token.actions.githubusercontent.com`. Staging reuses it with a **second deploy role** scoped to staging ECR/ECS only.

## References

- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [WAF for CloudFront (us-east-1)](https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html)
