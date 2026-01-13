variable "aws_region" {
  type        = string
  description = "AWS region"
}


variable "assume_role_arn" {
  type        = string
  description = "Role to assume for Terraform (optional). Empty = use current AWS credentials."
  default     = ""
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name (staging|production)"
}
