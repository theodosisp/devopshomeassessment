# Monitoring sketch

Rough targets from the brief:

- Keep monthly availability roughly **99.9%** — we’d measure off ALB (target 5xx vs accepted requests), not gut feeling.
- **`GET /healthz`** through the ALB should stay under ~**300 ms at P95** once there’s real traffic to measure.

## Dashboard

Below is a barebones CloudWatch dashboard JSON — swap `REPLACE` with your actual ALB dimension (`LoadBalancer` full name). Save locally then:

```bash
aws cloudwatch put-dashboard --dashboard-name DevOpsAssessment-API --dashboard-body file://cw-dashboard-devops-assessment.json
```

Two widgets: P95 latency and 5xx count on the ALB. Enough to stare at during a deploy.

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/devops-assessment-staging-alb/REPLACE", { "stat": "p95" } ]
        ],
        "period": 60,
        "region": "eu-central-1",
        "title": "ALB /healthz P95 (staging — rename me)",
        "yAxis": { "left": { "min": 0 } }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/devops-assessment-staging-alb/REPLACE", { "stat": "Sum" } ]
        ],
        "period": 60,
        "region": "eu-central-1",
        "title": "Target 5xx"
      }
    }
  ]
}
```

## Alarms worth wiring

**SLO-ish composite** — CloudWatch composite alarm tying together “too many 5xx” and “latency blew past budget”. Exact metric math depends how you define error budget; starting point is two underlying alarms then OR them.

Snippet idea (you’ll fix ARNs / alarm names):

```bash
aws cloudwatch put-composite-alarm \
  --alarm-name devops-assessment-slo-burn \
  --alarm-rule "ALARM(high-5xx) OR ALARM(high-latency-p95)" \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:devops-alerts
```

**5-minute error budget hack** — alarm when bad responses spike relative to traffic. Usually needs `MetricMath` in a JSON file for `--metrics`; I didn’t check in a working example because dimensions differ per account.

**Cost** — billing metrics in CloudWatch lag and hurt my brain. Prefer AWS Budgets + SNS (see `COST_NOTES.md`) for “we spent too much today” vibes.
