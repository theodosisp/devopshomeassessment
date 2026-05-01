variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project" {
  type    = string
  default = "devops-assessment"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "vpc_cidr" {
  type        = string
  description = "Isolated staging VPC CIDR (must not overlap prod in same account)."
  default     = "10.10.0.0/16"
}

variable "static_site_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket for staging static site."
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "ecr_repository_name" {
  type        = string
  description = "Separate staging ECR repo from prod (blast radius + clearer tagging)."
  default     = "devops-assessment-staging-api"
}

variable "bootstrap_container_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:alpine"
}

variable "task_cpu" {
  type        = number
  description = "Reduced Fargate CPU for staging cost."
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "512 MiB pairs with 256 CPU on Fargate."
  default     = 512
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "rds_identifier_stub" {
  type        = string
  description = "STUB ONLY — no RDS resources provisioned."
  default     = "devops-assessment-staging-db-not-created"
}
