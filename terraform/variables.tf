variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "fort-knox-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.42.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.42.2.0/24"
}

variable "admin_cidr" {
  description = "Your public IP/CIDR allowed to SSH to bastion (example: 203.0.113.10/32)"
  type        = string
}

variable "malicious_cidr" {
  description = "CIDR block explicitly denied by NACL"
  type        = string
  default     = "203.0.113.50/32"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion and processor"
  type        = string
  default     = "t3.micro"
}

variable "private_instance_count" {
  description = "Number of private processing instances"
  type        = number
  default     = 1
}

variable "processor_ami_id" {
  description = "Optional AMI ID for private processor instances (should include AWS CLI). Leave empty to use latest Amazon Linux 2023 AMI."
  type        = string
  default     = ""
}
