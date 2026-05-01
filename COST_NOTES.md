# Cost and performance

Short comparison of edge options for a small HTTP service.

## Routing options

**Application Load Balancer with ECS** — Currently used. Billing includes the load balancer hourly charge and LCU usage. Health checks integrate cleanly with ECS and Fargate.

**API Gateway with Lambda or ECS** — Useful when fine-grained auth or per-request billing matters more; adds operational complexity compared to a plain ALB for this workload.

**CloudFront alone** — Appropriate mainly for static content. Serving a container API typically requires additional patterns (for example Lambda@Edge or other routing).

For this project, ALB with ECS Fargate is a straightforward fit.

## Autoscaling

Application Auto Scaling for ECS is not fully implemented in Terraform here; it can be added later. A typical approach is target tracking on CPU (for example around 70%) or requests per target once baseline metrics exist. Use separate cooldowns for scale-out and scale-in to reduce oscillation.

## Static assets

CloudFront uses managed cache behaviours for static content. Use content hashing in filenames for long cache TTLs without serving stale application bundles.

## Budgets

Configure AWS Budgets with notifications (for example at 80% and 100% of a monthly limit) and SNS or email subscribers.

When cost thresholds are breached, pause production deployments via GitHub Environment protection or process until the cause is understood. Automated responses (for example EventBridge) can be added if needed.

### Example budget CLI

Replace account identifiers and notification endpoints before use:

```bash
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget file://budget.json --notifications-with-subscribers file://budget-notifications.json
```

Example `budget.json`:

```json
{
  "BudgetName": "devops-assessment-daily",
  "BudgetLimit": { "Amount": "25", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```
