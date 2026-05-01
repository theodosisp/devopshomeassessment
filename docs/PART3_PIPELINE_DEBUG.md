# Part 3 — Pipeline failure analysis

The failing GitHub Actions run reported three errors. Two were independent root causes; the third followed from the failed Docker build.

## Log excerpts

1. Docker build: `failed to read dockerfile: open Dockerfile: no such file or directory`
2. Trivy: `FATAL image not found in local store`
3. Amazon ECR login: `The security token included in the request is expired`

## Root causes

**Build context.** The workflow executed `docker build` without a `Dockerfile` in the working directory, or the file was not present in the committed repository.

**AWS credentials.** The credentials used for `aws ecr get-login-password` were no longer valid (expired session, rotated keys, or equivalent). The intended correction is short-lived credentials via GitHub OIDC and `aws-actions/configure-aws-credentials`, avoiding static keys in CI where possible.

## Dependent failure

Trivy scans a container image that must exist locally after `docker build`. If the build step fails, no image is present and Trivy reports that nothing is available to scan. Addressing only authentication does not create an image; addressing only the Dockerfile does not fix push until credentials are valid.

Recommended step order: checkout, configure AWS credentials (OIDC), Amazon ECR login, `docker build` from the directory that contains the `Dockerfile`, Trivy, then image push.

## Changes in this repository

- `Dockerfile` at repository root so the default build context works.
- `app/nginx/default.conf` responds with HTTP 200 on `GET /healthz` for health checks.
- `.github/workflows/ci.yml` updated to follow the sequence above.

Store `AWS_ROLE_ARN_STAGING` in GitHub Actions secrets from Terraform staging outputs. The workflow must include `permissions: id-token: write` for OIDC.

Verification checklist:

- `docker build` uses a path where `Dockerfile` exists.
- AWS authentication for CI is non-expiring under normal OIDC use.
- Trivy runs after a successful build.
