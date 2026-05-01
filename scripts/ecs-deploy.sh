#!/usr/bin/env bash
# Deploy new ECR image to ECS Fargate by registering a new task definition revision.
# Usage: ecs-deploy.sh <cluster> <service> <full-ecr-image-uri> <task-definition-family>
set -euo pipefail

CLUSTER="${1:?cluster}"
SERVICE="${2:?service}"
IMAGE_URI="${3:?image uri}"
FAMILY="${4:?task family}"

TD_JSON=$(aws ecs describe-task-definition \
  --task-definition "$FAMILY" \
  --include TAGS \
  --query 'taskDefinition' \
  --output json)

NEW_TD=$(echo "$TD_JSON" | jq --arg IMG "$IMAGE_URI" '
  del(
    .taskDefinitionArn,
    .revision,
    .status,
    .requiresAttributes,
    .compatibilities,
    .registeredAt,
    .registeredBy,
    .deregisteredAt,
    .tags
  )
  | .containerDefinitions |= map(if .name == "app" then .image = $IMG else . end)
')

NEW_ARN=$(aws ecs register-task-definition --cli-input-json "$NEW_TD" --query 'taskDefinition.taskDefinitionArn' --output text)

aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$NEW_ARN" \
  --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50"

echo "Deployed task definition: $NEW_ARN"
