variable "name_prefix" {
  type        = string
  description = "Prefix for resource names (e.g. devops-assessment-staging)."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR (must not overlap other VPCs in the account)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to supported resources."
}
