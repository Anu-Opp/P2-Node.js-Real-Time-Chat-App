output "public_ip" {
  value       = aws_eip.chat_eip.public_ip
  description = "Public IP of the chat server"
}

output "instance_id" {
  value       = aws_instance.chat_server.id
  description = "EC2 Instance ID"
}

output "security_group_id" {
  value       = aws_security_group.chat_sg.id
  description = "Security Group ID"
}
