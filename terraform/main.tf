data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  processor_ami_id = var.processor_ami_id != "" ? var.processor_ami_id : data.aws_ami.amazon_linux_2023.id
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "${var.project_name}-public-nacl"
  }
}

resource "aws_network_acl_rule" "public_deny_malicious" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  rule_number    = 100
  cidr_block     = var.malicious_cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "public_allow_ssh_in" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 110
  cidr_block     = var.admin_cidr
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "public_allow_ephemeral_in" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 120
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_allow_all_out" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH from admin IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Allow SSH only from bastion security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-sg"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "sensitive_data" {
  bucket        = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-sensitive-data"
  }
}

resource "aws_s3_bucket_public_access_block" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "private_instance" {
  name = "${var.project_name}-private-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "private_s3_access" {
  name = "${var.project_name}-private-s3-access"
  role = aws_iam_role.private_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          aws_s3_bucket.sensitive_data.arn
        ]
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.sensitive_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "private" {
  name = "${var.project_name}-private-profile"
  role = aws_iam_role.private_instance.name
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  }
}

resource "aws_instance" "processor" {
  count                       = var.private_instance_count
  ami                         = local.processor_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.private.id]
  iam_instance_profile        = aws_iam_instance_profile.private.name
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-processor-${count.index + 1}"
    Role = "processor"
  }
}
