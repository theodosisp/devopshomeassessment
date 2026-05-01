# Observability — dashboards & alerts (Part 5)

**SLO targets (from assessment)**

- **Availability**: monthly API ≥ **99.9%** (measure from ALB **HTTPCode_Target_5XX_Count** vs request count).
- **Latency**: **P95 ≤ 300 ms** on **`GET /healthz`** through ALB.

---

## One dashboard (CloudWatch — JSON stub)

Save as `cw-dashboard-devops-assessment.json` and create:

```bash
aws cloudwatch put-dashboard --dashboard-name DevOpsAssessment-API --dashboard-body file://cw-dashboard-devops-assessment.json
```

**Minimal stub** (edit `LoadBalancer` dimension / region):

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
        "title": "ALB /healthz P95 (staging example)",
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
        "title": "Target 5xx (staging example)"
      }
    }
  ]
}
```

---

## Three alert rules (stubs)

### 1) SLO burn (Composite Alarm skeleton)

Use **CloudWatch Metrics Insights** or separate alarms on **error budget** (requires custom metric math). Stub:

```bash
# Pseudocode: combine 5xx rate + latency alarm via Composite Alarm when either breaching
aws cloudwatch put-composite-alarm \
  --alarm-name devops-assessment-slo-burn \
  --alarm-rule "ALARM(high-5xx) OR ALARM(high-latency-p95)" \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:devops-alerts
```

### 2) Five-minute error rate > 2%

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name devops-assessment-error-rate-5m \
  --alarm-description "Target 5xx / requests > 2% over 5m (tune MetricMath)" \
  --metrics file://error-rate-metric-math.json \
  --evaluation-periods 1 \
  --threshold 2 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:devops-alerts
```

*`error-rate-metric-math.json`* must define `Expression` for ratio — replace `ACCOUNT`, SNS ARN, and dimensions.

### 3) Daily cost threshold

Prefer **AWS Budgets** + SNS (see `COST_NOTES.md`). CloudWatch billing metrics are account-level and delayed — budgets are clearer for “daily cost” guardrails.
