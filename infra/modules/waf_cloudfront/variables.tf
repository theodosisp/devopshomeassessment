variable "name_prefix" {
  type        = string
  description = "Name prefix for WAF resources."
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "CloudFront distribution ARN to associate (scope=CLOUDFRONT ACL must live in us-east-1)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to supported resources."
}
