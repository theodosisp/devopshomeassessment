# Part 1 — Bug fix notes (for your submission)

The starter snippet in the assessment PDF contained **four defects**. Mapping:

| # | Symptom | Root cause | Fix |
|---|---------|------------|-----|
| 1 | **`terraform plan` fails** — invalid reference | CloudFront `origin.domain_name` used `aws_s3_bucket.static`, but the bucket resource is named **`static_site`** | Use `aws_s3_bucket.static_site.bucket_regional_domain_name` |
| 2 | **`terraform plan` / apply fails or ACL rejected** (provider/AWS defaults) | **`acl = "public-read"`** on `aws_s3_bucket` — deprecated pattern with modern ownership controls; many accounts block public ACLs | Private bucket + **S3 ownership controls** + **public access block** + **CloudFront Origin Access Control (OAC)** + **bucket policy** scoped to the distribution ARN |
| 3 | **Silent misconfiguration** | **`viewer_protocol_policy = "allow-all"`** keeps HTTP open between viewer and CloudFront | **`redirect-to-https`** so users are forced to HTTPS |
| 4 | **Security / IaC scan (e.g. Trivy)** | Public-read / internet-facing bucket pattern | No public ACL; objects reachable only via CloudFront using OAC + least-privilege bucket policy |

After fixes, run from `infra/envs/part1`:

```bash
terraform init
terraform plan -out=tfplan
```

Keep the **plan output** or screenshot for the employer.
