variable "name_prefix" {
  type        = string
  description = "IAM role / policy name prefix."
}

variable "create_oidc_provider" {
  type        = bool
  default     = true
  description = "Create GitHub OIDC provider (only once per AWS account; staging should set false)."
}

variable "github_org" {
  type        = string
  description = "GitHub org or user (repo owner)."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name only (without org)."
}

variable "ecr_repository_arn" {
  type        = string
  description = "ECR repo ARN for scoped push/pull."
}

variable "ecs_cluster_arn" {
  type        = string
}

variable "ecs_service_arn" {
  type        = string
  description = "Full ECS service ARN."
}

variable "execution_role_arn" {
  type        = string
}

variable "task_role_arn" {
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
