variable "name_prefix" {
  type        = string
  description = "Prefix for ECS/ALB names."
}

variable "aws_region" {
  type        = string
  description = "Region for awslogs."
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Container listen port."
}

variable "task_cpu" {
  type        = number
  description = "Fargate CPU units (256, 512, 1024, ...)."
}

variable "task_memory" {
  type        = number
  description = "Fargate memory (MiB); must match CPU."
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Desired ECS task count."
}

variable "container_image" {
  type        = string
  description = "Bootstrap image until CI pushes to ECR."
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "ALB target group health check path (use /healthz when app image is deployed)."
}

variable "log_retention_days" {
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
