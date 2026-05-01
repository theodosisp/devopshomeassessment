# Backups, DR & on-call (Part 6)

## RDS (hypothetical — not provisioned here)

If a database existed:

| Topic | Recommendation |
|------|------------------|
| **Backup frequency** | Automated backups daily + **PITR** if supported |
| **Retention** | 7–35 days per compliance |
| **Restore test** | Quarterly restore into staging VPC |

## DR concept — CloudFront

- **Origin failover**: secondary origin (e.g. secondary bucket or API) via CloudFront origin group for static tier.
- **State**: Terraform remote state (S3 + DynamoDB lock) must be protected (versioning, SSE-KMS); document restore of state before infra rebuild.

## On-call — first 15 minutes checklist

1. **Acknowledge** alert (PagerDuty/Opsgenie/manual thread).
2. **Identify scope**: CDN vs ALB vs ECS vs downstream — check CloudWatch ALB 5xx, ECS deployment events, recent deploys.
3. **Stabilize**: if deploy-related — **rollback ECS** (`scripts/ecs-rollback.sh`) or revert GitHub deploy workflow input.
4. **Communicate**: post incident summary in `#incidents` with impact + ETA.

### Comms template (stub)

> We are investigating elevated 5xx from the staging ALB starting HH:MM UTC. Impact: optional description. Next update in 15 minutes.

### Rollback steps (reference)

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

Then verify **`GET /healthz`** via ALB DNS.

### Postmortem template (stub)

- **Timeline** — detection, mitigation, resolution  
- **Root cause** — technical + contributing factors  
- **What went well / poorly**  
- **Action items** — owner + due date  
