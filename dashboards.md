# Observability

Target indicators aligned with the assessment brief:

- Monthly API availability around **99.9%**, derived from Application ELB metrics (for example target 5xx versus accepted requests).
- **P95 latency** for `GET /healthz` through the ALB below **300 ms** once sufficient traffic exists for measurement.

## CloudWatch dashboard

The JSON below is a minimal dashboard template. Replace `REPLACE` with the full `LoadBalancer` dimension for your environment. Save as `cw-dashboard-devops-assessment.json`, then create the dashboard:

```bash
aws cloudwatch put-dashboard --dashboard-name DevOpsAssessment-API --dashboard-body file://cw-dashboard-devops-assessment.json
```

Widgets cover ALB target response time (P95) and target 5xx counts.

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
        "title": "ALB target response time P95 (staging)",
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
        "title": "Target 5xx count"
      }
    }
  ]
}
```

## Alarms

**Composite alarm for SLO burn** — Combine alarms on elevated 5xx rate and high latency using a CloudWatch composite alarm. Underlying alarm names and ARNs depend on your setup.

Example outline:

```bash
aws cloudwatch put-composite-alarm \
  --alarm-name devops-assessment-slo-burn \
  --alarm-rule "ALARM(high-5xx) OR ALARM(high-latency-p95)" \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:devops-alerts
```

**Error rate over five minutes** — Typically implemented with MetricMath comparing 5xx to total requests; dimensions vary by account. Store metric definitions in a JSON file passed to `put-metric-alarm`.

**Cost** — AWS Budgets with SNS (see `COST_NOTES.md`) is often clearer than relying solely on CloudWatch billing metrics, which can lag.
