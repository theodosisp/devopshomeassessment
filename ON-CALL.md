# When things break (and DR thoughts)

## Database

There isn’t one in this repo — `rds_identifier_stub` is literally a text placeholder. If we had Postgres/RDS anyway: turn on automated backups, keep retention sane for your compliance story, test restores into staging once in a while so you’re not learning backup restoration during a production fire.

## Static tier / CloudFront

If the primary S3 origin dies, an origin group with a standby bucket (or another regional endpoint) is the boring DR pattern for static content. Terraform state for all this lives in S3 with Dynamo locking — version the bucket, encrypt it, don’t hand-delete objects when you’re tired.

## First 15 minutes after a page

1. Acknowledge you saw the alert — nobody likes screaming into void Slack forever.
2. Figure out *where* it hurts: CloudFront vs ALB vs ECS vs something downstream. CloudWatch ALB metrics + ECS events + “what did we ship last” usually answer that fast.
3. If it smells like a bad deploy, roll ECS back (`scripts/ecs-rollback.sh` with the last known-good task def ARN) before you chase ghosts in application code.
4. Post something short in the incident channel: what’s broken, who’s looking, when you’ll update again.

Blurb you can paste (edit times):

> Seeing elevated 5xx on `<env>` ALB since ~HH:MM UTC. Investigating. Next note in ~15m unless we’ve fixed it.

Rollback reminder:

```bash
bash scripts/ecs-rollback.sh "$CLUSTER" "$SERVICE" "$PREVIOUS_TASK_DEF_ARN"
```

Then hit `http://<alb-dns>/healthz` yourself — don’t trust green CI alone.

## After it’s over

Short retro beats nothing: timeline, root cause (including “we shipped fast without tests”), what helped, what didn’t, action items with owners. Doesn’t need to be a novel.
