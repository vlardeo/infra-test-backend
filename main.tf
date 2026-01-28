data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "vpc" {
  source = "./modules/vpc"

  name                 = "${var.project}-${var.environment}"
  cidr                 = var.vpc_cidr
  az_count             = 2
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  nat_mode             = var.nat_mode

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_security_group" "web" {
  name        = "${var.project}-${var.environment}-web"
  description = "Web SG for ${var.project} (${var.environment})"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (temporary, tighten later)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web.id]
  subnet_id                   = module.vpc.public_subnet_ids[0]
  associate_public_ip_address = true

  tags = {
    Name        = "${var.project}-${var.environment}-web"
    Project     = var.project
    Environment = var.environment
  }
}
