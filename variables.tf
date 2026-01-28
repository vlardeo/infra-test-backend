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

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "nat_mode" {
  type        = string
  description = "NAT mode: single | per_az"
  default     = "per_az"
}
