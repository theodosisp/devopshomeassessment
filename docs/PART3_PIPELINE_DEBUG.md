# Part 3 — Debug the failed staging pipeline

## Original failure summary (from the assessment)

Three error blocks appeared in one GitHub Actions run:

1. **Docker build** — `failed to read dockerfile: open Dockerfile: no such file or directory`
2. **Trivy** — `FATAL image not found in local store`
3. **AWS ECR login** — `The security token included in the request is expired`

## Root cause A — Dockerfile / build context

**What happened:** The workflow ran `docker build` from a working directory that did **not** contain a `Dockerfile`, or the `Dockerfile` was never committed to the repository.

**Effect:** No container image was produced locally.

## Root cause B — Expired AWS credentials for ECR

**What happened:** The step that calls `aws ecr get-login-password` used credentials that were **no longer valid** (expired session token, rotated keys, or wrong temporary credentials).

**Effect:** Even after fixing the Dockerfile, pushes to ECR would fail until authentication uses **fresh** credentials — typically **GitHub OIDC → IAM role** instead of long-lived static keys in CI.

## Dependency — which error is *not* its own root cause?

**The Trivy failure is a consequence of root cause A.**

- Trivy scans a **local Docker image** referenced by tag.
- If `docker build` never succeeded, **no image exists locally**, so Trivy reports **image not found in local store**.
- Fixing only AWS login first does **not** create an image; Trivy still fails until the image is built.

## Why order of fixes matters

| If you fix… first | Result |
|-------------------|--------|
| **AWS only** | Build still fails (no Dockerfile/path) → no image → Trivy still fails |
| **Dockerfile/path only** | Image builds → Trivy can scan locally → **push** to ECR still fails until AWS auth is fixed |
| **Dockerfile then AWS auth** | Image builds → Trivy passes → ECR login/push can succeed |

Recommended sequence in the workflow YAML:

1. **Checkout** (so `Dockerfile` is on the runner)
2. **Configure AWS credentials** via OIDC (`configure-aws-credentials`) — short-lived, non-expired pattern
3. **Amazon ECR login**
4. **`docker build`** from the directory that contains `Dockerfile` (repository root in this repo)
5. **Trivy** scan the built image tag
6. **`docker push`** (when ready for registry)

## Deliverables in this repo

| Artifact | Purpose |
|----------|---------|
| [`Dockerfile`](../Dockerfile) at repo root | Fixes “no Dockerfile” when build runs from `.` |
| [`app/nginx/default.conf`](../app/nginx/default.conf) | Serves **`GET /healthz`** with HTTP 200 for Part 4 health gates |
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | Corrected workflow with inline comments |

## GitHub configuration you must add

After `terraform apply` on **staging**, set repository secrets:

- **`AWS_ROLE_ARN_STAGING`** — value from `terraform output github_deploy_role_arn_staging` (staging env).

Optional variable (or hardcode in workflow):

- **`ECR_REPOSITORY`** — default `devops-assessment-staging-api` (must match Terraform).

Workflow uses **`permissions: id-token: write`** so OIDC tokens can be exchanged for AWS credentials.

## Self-check

- [ ] `Dockerfile` exists at path used by `docker build`
- [ ] AWS auth uses OIDC or otherwise non-expired credentials
- [ ] Trivy runs **after** a successful `docker build`
- [ ] You can explain why Trivy was a **follow-on** failure, not a third independent bug
