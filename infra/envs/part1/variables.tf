variable "aws_region" {
  type        = string
  description = "AWS region for Part 1 test."
  default     = "eu-central-1"
}

variable "bucket_name" {
  type        = string
  description = "Must be globally unique across all AWS (change this!)."
}
