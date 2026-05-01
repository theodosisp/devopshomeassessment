#!/usr/bin/env bash
# One-command rollback: point ECS service at a previous known-good task definition ARN.
# Usage: ecs-rollback.sh <cluster> <service> <previous-task-definition-arn>
# Find previous ARN: aws ecs list-task-definitions --family-prefix devops-assessment-prod-task --sort DESC --max-items 2
set -euo pipefail

CLUSTER="${1:?cluster}"
SERVICE="${2:?service}"
PREV_ARN="${3:?previous task definition ARN}"

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$PREV_ARN"

echo "Rollback requested to $PREV_ARN — verify health checks and Terraform drift."
