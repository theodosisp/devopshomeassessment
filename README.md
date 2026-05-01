# DevOps Home Assessment (v4.4)

This repository contains **Parts 1–6** of the DevOps Home Assessment (v4.4): Terraform, CI/CD (OIDC, Trivy, semver tags), gated **deploy** workflow, ops/security/cost docs.

## Layout

- `infra/modules/*`, `infra/envs/{part1,staging,prod}` — infrastructure as code
- `docs/PART3_PIPELINE_DEBUG.md` — Part 3 pipeline RCA
- `Dockerfile`, `app/nginx/` — **`GET /healthz` → 200**
- `.github/workflows/ci.yml` — build, smoke test, Trivy, push **SHA + semver** tags
- `.github/workflows/deploy.yml` — manual deploy + environment gates + `/healthz` check
- `scripts/ecs-deploy.sh`, `scripts/ecs-rollback.sh` — ECS roll forward / rollback
- `SECURITY.md`, `COST_NOTES.md`, `dashboards.md`, `ON-CALL.md` — Part 5–6 deliverables
- `submission/` — Part 1 plan artifact

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

## Part 3 — CI debug (completed)

See **`docs/PART3_PIPELINE_DEBUG.md`**. Set GitHub secret **`AWS_ROLE_ARN_STAGING`** from `terraform output github_deploy_role_arn_staging` before CI can assume AWS.

## Parts 4–6 — CI/CD, gates, docs (completed)

### CI (`ci.yml`)

1. Checkout → **OIDC** AWS credentials → **ECR login**
2. **`docker build`** at repo root (Dockerfile present)
3. **Smoke test** running container → **`curl /healthz`**
4. **Trivy** scan (`HIGH`, `CRITICAL` fail build)
5. On **`push` to `main`**: push image tags **`:<12-char-sha>`** and **`1.0.<run_number>`** (semver-style)

### Deploy (`deploy.yml`)

- Trigger: **`workflow_dispatch`** — choose **staging** or **production**, enter **`image_tag`** (the 12-char SHA printed by CI).
- Uses GitHub **Environments** `staging` / `production` — add **required reviewers** under repo **Settings → Environments** for manual gates.
- Steps: OIDC → **register task definition** (`scripts/ecs-deploy.sh`) → **wait services-stable** → **`curl` ALB `/healthz`**.

### Rollback (one command)

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

### GitHub configuration checklist

| Name | Type | Example source |
|------|------|----------------|
| `AWS_ROLE_ARN_STAGING` | Secret | `terraform output -raw github_deploy_role_arn_staging` |
| `AWS_ROLE_ARN_PROD` | Secret | `terraform output -raw github_deploy_role_arn_prod` |
| `ECS_CLUSTER_STAGING` | Variable | `terraform output -raw` → `ecs_cluster_name` (staging env) |
| `ECS_SERVICE_STAGING` | Variable | service name |
| `TASK_FAMILY_STAGING` | Variable | `devops-assessment-staging-task` |
| `STAGING_ALB_DNS` | Variable | ALB DNS hostname (no `http://`) |
| `ECS_CLUSTER_PRODUCTION` | Variable | prod cluster |
| `ECS_SERVICE_PRODUCTION` | Variable | prod service |
| `TASK_FAMILY_PRODUCTION` | Variable | `devops-assessment-prod-task` |
| `PROD_ALB_DNS` | Variable | prod ALB DNS |

Replace `devops-assessment-*` prefixes if you changed `project` / `environment` in Terraform.

### RDS stub

The **`rds_identifier_stub`** variables are **documentation-only** — no RDS instances are created here.

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
