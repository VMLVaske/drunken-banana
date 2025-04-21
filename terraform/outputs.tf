output "ec2_instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.ghost_ec2.id
}

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.ghost_ec2.public_ip
}

output "ec2_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.ghost_ec2.public_dns
}

output "ssh_command" {
  description = "Convenient SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/ghost-key.pem ubuntu@${aws_instance.ghost_ec2.public_ip}"
}

output "public_ip" {
  value = aws_eip.ghost.public_ip
}