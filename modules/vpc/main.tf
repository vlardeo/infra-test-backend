data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  common_tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for i, az in local.azs : i => az }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.public_subnet_cidrs[each.key]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${each.value}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = { for i, az in local.azs : i => az }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value
  cidr_block        = var.private_subnet_cidrs[each.key]

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.value}"
    Tier = "private"
  })
}

# --- Public routing ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rt-public"
  })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --- NAT ---
resource "aws_eip" "nat" {
  for_each = var.nat_mode == "per_az" ? aws_subnet.public : { 0 = aws_subnet.public[0] }

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name}-eip-nat-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = var.nat_mode == "per_az" ? aws_subnet.public : { 0 = aws_subnet.public[0] }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

# --- Private routing (one per AZ in per_az mode; one shared in single mode) ---
resource "aws_route_table" "private" {
  for_each = var.nat_mode == "per_az" ? aws_subnet.private : { 0 = aws_subnet.private[0] }

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-rt-private-${each.key}"
  })
}

resource "aws_route" "private_default" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.nat_mode == "per_az" ? each.key : 0].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = each.value.id

  route_table_id = var.nat_mode == "per_az" ? aws_route_table.private[each.key].id : aws_route_table.private[0].id
}
