variable "repository_name" {
  type        = string
  description = "ECR repository name."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to supported resources."
}
