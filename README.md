# DevOps Home Assessment (v4.4)

Terraform for S3/CloudFront + full staging/prod stacks, GitHub Actions for build/scan/deploy, and a pile of markdown nobody reads until audit season.

## What’s in here

Infra lives under `infra/` — modules plus `part1`, `staging`, `prod` envs. The tiny nginx container (`Dockerfile`, `app/nginx/`) serves `/healthz` so ALB checks have something to hit.

Workflows: `ci.yml` builds, smoke-tests, runs Trivy, pushes tags; `deploy.yml` is manual (`workflow_dispatch`) and expects GitHub Environments if you want human gates.

Scripts `ecs-deploy.sh` / `ecs-rollback.sh` wrap the boring ECS register/update dance.

`SECURITY.md`, `COST_NOTES.md`, `dashboards.md`, `ON-CALL.md` are rough notes — adjust tone for your company if you fork this.

`submission/` has the Part 1 plan output kept for the submission.

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

## Part 3 write-up

See `docs/PART3_PIPELINE_DEBUG.md`. CI needs secret **`AWS_ROLE_ARN_STAGING`** from Terraform staging outputs or it’ll fail at the OIDC step.

## CI / deploy (Parts 4+)

**ci.yml** — checkout, assume role via OIDC, ECR login, `docker build` from repo root, container smoke test on `/healthz`, Trivy (HIGH/CRITICAL fail the job), then on pushes to `main` tag and push both the short SHA and a `1.0.<run_number>` tag.

**deploy.yml** — run manually from Actions, pick staging vs prod, paste the image tag CI printed. Uses GitHub Environments if you configure reviewers under repo settings. Rolls ECS forward with `ecs-deploy.sh`, waits for steady state, curls the ALB `/healthz`.

Rollback when something ships sideways:

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

### GitHub secrets / vars you’ll fill in

| Name | Where |
|------|--------|
| `AWS_ROLE_ARN_STAGING` | Secret — `terraform output -raw github_deploy_role_arn_staging` (staging dir) |
| `AWS_ROLE_ARN_PROD` | Secret — prod deploy role ARN |
| `ECS_CLUSTER_STAGING`, `ECS_SERVICE_STAGING`, `TASK_FAMILY_STAGING`, `STAGING_ALB_DNS` | Variables — from staging `terraform output` |
| Same pattern for production | Prefix `ECS_CLUSTER_PRODUCTION` etc., plus `PROD_ALB_DNS` |

If you renamed `project` / `environment` in Terraform, your cluster/service/family strings won’t match `devops-assessment-*` — adjust vars accordingly.

No RDS was provisioned; `rds_identifier_stub` is just a variable placeholder.

## Why things look like this

Fargate + ALB instead of babysitting EC2 — fewer moving parts for a homework-sized service. You pay a bit more per unit of compute than a tuned EC2 box would cost; you buy back weekends not patching AMIs.

Two VPCs in one account instead of spinning a second AWS org — easier billing and IAM, weaker isolation than account boundaries. Good enough here; real prod governance might split accounts.

Separate ECR repos for staging and prod so nobody fat-fingers a prod deploy tag into staging’s repo by accident (or vice versa). Shared repo + discipline works too; separate repos were the lazier mental model here.

WAF only on prod CloudFront — staging is cheaper and messier on purpose. Know that the staging URL is softer; don’t put secrets there.

Single NAT gateway — saves ~one NAT’s worth of cash monthly; if NAT dies the private subnets lose outbound until AWS fixes the AZ. Acceptable for this repo; prod hardening might NAT per AZ.

OIDC provider gets created during prod Terraform apply once per account; staging just attaches another IAM role to the same GitHub trust. That’s an AWS limitation, not something we invented.

## Links I kept open

Terraform AWS provider docs, and the WAF + CloudFront region quirk (ACLs for CloudFront live in `us-east-1` even if the rest of the stack is in Frankfurt or wherever).

- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [WAF / CloudFront](https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html)
