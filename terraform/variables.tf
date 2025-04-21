variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to your public SSH key"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to use for EC2 access"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance (Ubuntu 22.04 LTS recommended)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to access the instance via SSH"
  type        = string
  default     = "0.0.0.0/0"
}
