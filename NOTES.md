Project 1: The "Fort Knox" Private Data Processor 🛡️

Focus: VPC Networking, Security Groups vs. NACLs, Route Tables, and VPC Endpoints (Cost Optimization).

The Scenario

A company needs to process sensitive data files stored in Amazon S3. The processing compute instances must sit in a private subnet, cannot have public IP addresses, and cannot use a NAT Gateway due to strict data-transfer budget constraints. Furthermore, the security team requires a hard network-level block on a known malicious IP range.

Architecture Overview

VPC: A custom VPC with 1 Public Subnet (for a Bastion Host) and 1 Private Subnet (for the processing instances).

Routing & Endpoints: A VPC Gateway Endpoint for Amazon S3 attached to the Private Subnet's route table.

Security: * NACLs: Attached to the public subnet explicitly denying inbound traffic from a mock "malicious" IP (e.g., 203.0.113.50/32).

Security Groups: The Bastion SG allows SSH from your IP. The Private Instance SG allows SSH only from the Bastion SG.

IAM: An EC2 Instance Profile granting the private instances read/write access to a specific S3 bucket.

Implementation Steps

Terraform: Write the Terraform code to provision the VPC, Subnets, Route Tables, Internet Gateway (for the public subnet), S3 Gateway Endpoint, Security Groups, NACLs, and the IAM Role/Instance Profile.

AWS CLI: Use the CLI to upload a sample "sensitive_data.txt" file to your newly provisioned S3 bucket.

Ansible: Write an Ansible playbook that targets the private instances (via the Bastion host as a jump box). The playbook should install the AWS CLI on the instances and run a script to securely download the file from S3 using the VPC Endpoint, simulating data processing.

Why this is a great portfolio piece:

It proves you understand the difference between SGs and NACLs, how to implement Least Privilege with IAM instance profiles, and how to architect for cost-efficiency using Gateway Endpoints instead of expensive NAT Gateways.
