variable "aws_region" {
  type        = string
  description = "Primary region for compute and edge (except WAF for CloudFront)."
  default     = "eu-central-1"
}

variable "project" {
  type        = string
  description = "Short project tag value."
  default     = "devops-assessment"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "Isolated prod VPC CIDR (must not overlap staging in same account)."
  default     = "10.20.0.0/16"
}

variable "static_site_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for static assets behind CloudFront."
}

variable "github_org" {
  type        = string
  description = "GitHub owner for OIDC trust (org or user)."
}

variable "github_repo" {
  type        = string
  description = "Repository name only."
}

variable "ecr_repository_name" {
  type        = string
  description = "ECR repository name for prod images."
  default     = "devops-assessment-prod-api"
}

variable "bootstrap_container_image" {
  type        = string
  description = "Until CI pushes to ECR, run a public image (nginx serves / for health)."
  default     = "public.ecr.aws/docker/library/nginx:alpine"
}

variable "task_cpu" {
  type        = number
  description = "Fargate CPU units for prod API task."
  default     = 512
}

variable "task_memory" {
  type        = number
  description = "Fargate memory (MiB) for prod API task."
  default     = 1024
}

variable "health_check_path" {
  type        = string
  description = "ALB health check path (switch to /healthz when app image is live)."
  default     = "/"
}

variable "rds_identifier_stub" {
  type        = string
  description = "STUB ONLY — no RDS resources are provisioned in this assessment repo."
  default     = "devops-assessment-prod-db-not-created"
}
