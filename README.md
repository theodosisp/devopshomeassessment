# DevOps Home Assessment (v4.4)

Terraform for static delivery (S3, CloudFront) and full staging and production stacks on AWS, plus GitHub Actions for build, vulnerability scanning, and deployment workflows.

## Repository contents

- **`infra/`** — Modules and environments (`part1`, `staging`, `prod`).
- **`Dockerfile`**, **`app/nginx/`** — Container image exposing **`GET /healthz`** for load balancer and pipeline checks.
- **`.github/workflows/ci.yml`** — Build, smoke test, Trivy, push image tags.
- **`.github/workflows/deploy.yml`** — Manual deployment via `workflow_dispatch`; optional GitHub Environment approvals.
- **`scripts/ecs-deploy.sh`**, **`scripts/ecs-rollback.sh`** — ECS task definition update and rollback helpers.
- **`SECURITY.md`**, **`COST_NOTES.md`**, **`dashboards.md`**, **`ON-CALL.md`** — Supporting documentation.
- **`submission/`** — Part 1 Terraform plan artifact.

## Remote state

Create an S3 bucket and a DynamoDB table for state locking, then configure `backend.hcl` per environment.

```bash
aws s3api create-bucket --bucket yourname-terraform-state-eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-bucket-versioning --bucket yourname-terraform-state-eu-central-1 --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

Copy `infra/envs/prod/backend.hcl.example` to `backend.hcl` (and staging separately with its own `key`).

Local validation without remote backend: `terraform init -backend=false`

## Apply order

1. **Production** first — creates the GitHub OIDC identity provider (once per account) and the production deploy role.
2. **Staging** second — uses `create_oidc_provider = false` and references the existing provider. Applying staging before production will fail until the provider exists.

## Commands

**Production** (after copying `terraform.tfvars.example` to `terraform.tfvars` and editing values):

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

**Part 1 (CDN module only):**

```bash
cd infra/envs/part1
terraform init
terraform plan -out=tfplan
```

Use `terraform output` for ALB DNS, ECR URLs, and IAM role ARNs.

## Part 3

Details: **`docs/PART3_PIPELINE_DEBUG.md`**. Configure GitHub secret **`AWS_ROLE_ARN_STAGING`** from staging Terraform output before OIDC-based CI can succeed.

## CI and deployment

**`ci.yml`** — Checkout, OIDC to AWS, ECR login, `docker build` at repository root, container smoke test on `/healthz`, Trivy (HIGH and CRITICAL fail the job). On push to `main`, images are tagged with the short commit SHA and `1.0.<workflow_run_number>`.

**`deploy.yml`** — Run from the Actions tab; select staging or production and enter the image tag produced by CI. Optional environment protection rules add manual approval. Deployment registers a new ECS task definition, waits for service stability, and checks `/healthz` on the load balancer.

Rollback:

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

### GitHub configuration

| Name | Type | Source |
|------|------|--------|
| `AWS_ROLE_ARN_STAGING` | Secret | `terraform output -raw github_deploy_role_arn_staging` (staging) |
| `AWS_ROLE_ARN_PROD` | Secret | Production deploy role ARN |
| `ECS_CLUSTER_STAGING`, `ECS_SERVICE_STAGING`, `TASK_FAMILY_STAGING`, `STAGING_ALB_DNS` | Variables | Terraform outputs (staging) |
| `ECS_CLUSTER_PRODUCTION`, `ECS_SERVICE_PRODUCTION`, `TASK_FAMILY_PRODUCTION`, `PROD_ALB_DNS` | Variables | Terraform outputs (production) |

If `project` or `environment` names were changed in Terraform, adjust resource name prefixes instead of the defaults shown above.

RDS is not deployed; `rds_identifier_stub` is documentation-only.

## Design notes

- **Fargate and ALB** — Reduces operational overhead compared to self-managed EC2; cost per unit of compute may be higher than optimised EC2 for steady workloads.
- **Two VPCs in one account** — Simplifies networking and billing; weaker isolation than separate AWS accounts for production governance.
- **Separate ECR repositories** — Clear separation between staging and production images; a single repository with strict tagging is an alternative.
- **WAF on production CloudFront only** — Staging omits WAF to control cost; staging endpoints should not host sensitive data.
- **Single NAT gateway** — Lower cost; consider redundant NAT per availability zone for higher availability requirements.
- **OIDC provider** — Created during production apply; staging uses a dedicated IAM role against the same GitHub OIDC provider (AWS limit of one issuer URL per account for this integration).

## References

- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS WAF and CloudFront](https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html) (WAF for CloudFront is configured in `us-east-1`.)
