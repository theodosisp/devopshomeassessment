# Cost / perf scribbles

Quick comparison we’d actually have in a design doc — nothing authoritative.

## How traffic hits the app

**ALB + ECS** — what we built. You pay for the load balancer hour-by-hour plus LCU usage. Health checks are straightforward and ECS hooks up without gymnastics. Fine for a small API behind `/healthz`.

**API Gateway in front of Lambda or ECS** — nice when you care about per-request billing or JWT validation at the edge. Adds complexity (and cold starts if you go Lambda) that we didn’t need for this repo.

**CloudFront-only** — great when it’s mostly static files. Not really a replacement for a container API unless you’re okay bolting Lambda@Edge / weird routing on top.

So ALB + Fargate it is.

## Autoscaling

Didn’t bake autoscaling resources into Terraform yet — call it a stub. When metrics exist, target-tracking on CPU (~70%) or requests-per-task is the boring default. Cooldowns around 60s scale-out / 300s scale-in so it doesn’t flap every traffic blip.

## Caching static assets

CloudFront side uses AWS managed cache policies for the CDN behaviour. For JS/CSS, ship hashed filenames (`app.a1b2c3.js`) so you can crank TTLs without cache poisoning scare stories.

## Money alarms

Budgets in AWS (monthly cap + SNS email at ~80% and 100%) beat staring at the billing console on Sundays.

If finance calls panicking, flip the production GitHub Environment to “nobody deploys until we talk” — low-tech but works. Wiring EventBridge to auto-disable webhooks is overkill until it isn’t.

### Budget CLI skeleton

Replace account IDs / emails before running:

```bash
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget file://budget.json --notifications-with-subscribers file://budget-notifications.json
```

Example `budget.json` shape:

```json
{
  "BudgetName": "devops-assessment-daily",
  "BudgetLimit": { "Amount": "25", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
```
