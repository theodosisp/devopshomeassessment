provider "aws" {
  region = var.aws_region
}

# WAF for CloudFront must be created in us-east-1 (associate with CloudFront distribution).
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
