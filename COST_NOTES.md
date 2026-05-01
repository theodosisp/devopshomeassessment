# Cost & performance (Part 5)

## ALB vs API Gateway vs CloudFront-only (small service)

| Option | Pros | Cons |
|--------|------|------|
| **ALB + ECS** | Native HTTP/TCP health checks, sticky sessions possible, simple ECS attach | Hourly ALB cost + LCUs |
| **API Gateway + Lambda/ECS** | Fine-grained auth, usage billing | Cold starts / complexity for tiny APIs |
| **CloudFront-only** | Cheapest edge — great for **static** assets | Not a substitute for dynamic API routing without Lambda@Edge / Functions URLs |

**Choice here**: **ALB + ECS Fargate** for the container API (`/healthz`) — simplest path for ECS health checks and aligns with assessment diagram.

## Autoscaling (default policy — stub)

- **ECS**: enable target tracking on **ALB target group** request count per task / CPU — start at **target 70% CPU** or **60 RPS/task** after metrics baseline (Terraform `aws_appautoscaling_*` not committed — stub).
- **Scale-out cooldown** 60s, **scale-in** 300s to avoid flapping.

## Static asset caching

- CloudFront uses **managed caching** policy on static behaviour; version filenames (`app.v123.js`) for safe long TTLs.

## Daily budget guardrail

1. **AWS Budgets**: monthly cost budget with email/SNS alert at e.g. **80%** and **100%**.
2. **Pipeline toggle**: add GitHub Environment **`production`** protection rule “pause deploys” manually when budget alarm fires; optional AWS EventBridge → disable pipeline webhook (future).

### Budget stub (CLI — replace account/email)

```bash
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget file://budget.json --notifications-with-subscribers file://budget-notifications.json
```

**budget.json** (example skeleton):

```json
{
  "BudgetName": "devops-assessment-daily",
  "BudgetLimit": { "Amount": "25", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```
