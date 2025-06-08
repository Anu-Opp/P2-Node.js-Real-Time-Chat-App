output "chat_app_ip" {
  value       = aws_eip.chat_eip.public_ip
  description = "Public IP of the chat server"
}

output "jenkins_ip" {
  value       = aws_eip.jenkins_eip.public_ip
  description = "Public IP of the Jenkins server"
}

output "chat_instance_id" {
  value       = aws_instance.chat_server.id
  description = "Chat App Instance ID"
}

output "jenkins_instance_id" {
  value       = aws_instance.jenkins_server.id
  description = "Jenkins Instance ID"
}

output "vpc_id" {
  value       = aws_vpc.chat_vpc.id
  description = "VPC ID"
}