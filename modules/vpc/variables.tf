variable "name" {
  type        = string
  description = "Name prefix for VPC resources"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "az_count" {
  type        = number
  description = "How many AZs to use (min 2 recommended)"
  default     = 2
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (length must equal az_count)"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (length must equal az_count)"
}

variable "nat_mode" {
  type        = string
  description = "NAT mode: single | per_az"
  default     = "per_az"

  validation {
    condition     = contains(["single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be 'single' or 'per_az'."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
