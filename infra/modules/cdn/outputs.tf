output "bucket_id" {
  value       = aws_s3_bucket.static_site.id
  description = "S3 bucket name."
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "CloudFront hostname (HTTPS)."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cdn.id
  description = "CloudFront distribution ID."
}
