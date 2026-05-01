# Operations, backup, and on-call

## Database

No RDS instance is deployed in this repository; `rds_identifier_stub` is a placeholder variable only.

If a relational database were introduced: enable automated backups with retention aligned to policy, consider point-in-time recovery where supported, and verify restores periodically (for example into a non-production environment).

## Disaster recovery (static tier)

For static content behind CloudFront, origin failover via an origin group (secondary S3 bucket or endpoint) is a common pattern.

Terraform state is stored remotely (S3 with versioning recommended; DynamoDB for locking). Protect the state bucket with encryption and lifecycle policies; avoid destructive operations on state objects outside controlled procedures.

## First response after an alert

1. Acknowledge the incident in the agreed channel or tooling.
2. Narrow scope: CloudFront, load balancer, ECS, or downstream dependency. Use CloudWatch metrics for the ALB, ECS service events, and recent deployments as primary signals.
3. If a deployment is suspected, consider rolling back the ECS service using `scripts/ecs-rollback.sh` with the last known-good task definition ARN before deeper application debugging.
4. Post a short status update: impact, owner, and next update time.

Example stakeholder message (adjust timestamps and environment):

> Elevated 5xx responses observed on `<environment>` ALB since HH:MM UTC. Under investigation. Next update in approximately 15 minutes.

Rollback command:

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

Confirm `GET /healthz` on the load balancer DNS after rollback.

## Post-incident review

Document timeline, root cause, corrective actions, and follow-up tasks with owners. A concise summary is sufficient for smaller incidents.
