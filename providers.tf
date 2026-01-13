provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []

    content {
      role_arn = var.assume_role_arn
    }
  }
}
