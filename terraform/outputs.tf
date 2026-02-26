output "aws_region" {
  value       = var.aws_region
  description = "Region where resources were created"
}

output "bucket_name" {
  value       = aws_s3_bucket.sensitive_data.bucket
  description = "S3 bucket for sensitive files"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP of bastion host"
}

output "private_instance_ids" {
  value       = aws_instance.processor[*].id
  description = "IDs of private processing instances"
}

output "private_instance_private_ips" {
  value       = aws_instance.processor[*].private_ip
  description = "Private IPs of processing instances"
}

output "processor_ami_id" {
  value       = local.processor_ami_id
  description = "AMI used for private processing instances"
}

output "ansible_ssh_common_args" {
  value       = "-o ProxyCommand='ssh -W %h:%p -i <path-to-key.pem> ec2-user@${aws_instance.bastion.public_ip}'"
  description = "Ansible SSH proxy args template through bastion"
}
