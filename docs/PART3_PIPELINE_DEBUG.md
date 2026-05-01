# Part 3 — what broke in that staging workflow

The pdf threw three red blocks in one run. Two were real bugs; the third was basically fallout.

## What the logs said

1. Docker couldn’t open `Dockerfile` — classic wrong directory or file never committed.
2. Trivy complained there was no image locally.
3. `aws ecr get-login-password` blew up with an expired security token.

## Actually broken

**Build context.** Either the workflow `cd`’d somewhere without a Dockerfile, or the Dockerfile wasn’t in git at all. Until that’s fixed there is nothing for Docker to build.

**AWS auth.** Whatever credentials the job used for ECR were stale — old access keys in secrets, expired OIDC session assumptions, whatever. Fix is usually “stop using long-lived keys in CI” and wire OIDC + `configure-aws-credentials` like a normal person.

## The Trivy line isn’t a separate mystery

Trivy scans an image tag that should exist on disk after `docker build`. If build never ran, there is no image — so it errors out with “not in local store”. Fixing only AWS login doesn’t magically materialise an image; fixing only Dockerfile doesn’t help push if auth is still dead.

Order that actually works: get code on the runner → assume AWS via OIDC → `docker build` from the folder that has the Dockerfile → then Trivy → then push.

## What landed in this repo

- `Dockerfile` at the repo root so `docker build .` isn’t lying.
- `app/nginx/default.conf` answering `/healthz` with 200 (same thing the ALB checks later).
- `ci.yml` reordered around OIDC + build + scan.

Before CI goes green you’ll need `AWS_ROLE_ARN_STAGING` in GitHub from Terraform output. Workflow also needs `id-token: write` permissions or OIDC silently frustrates you.

Quick sanity check before you submit the write-up:

- `docker build` path matches where the file lives.
- AWS creds aren’t expiring mid-pipeline.
- Trivy runs after a successful build, not before.
