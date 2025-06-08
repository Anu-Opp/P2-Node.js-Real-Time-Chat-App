provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "chat_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "chat-app-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "chat_igw" {
  vpc_id = aws_vpc.chat_vpc.id
  
  tags = {
    Name = "chat-app-igw"
  }
}

# Public Subnet
resource "aws_subnet" "chat_public_subnet" {
  vpc_id                  = aws_vpc.chat_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "chat-app-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "chat_public_rt" {
  vpc_id = aws_vpc.chat_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chat_igw.id
  }
  
  tags = {
    Name = "chat-app-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "chat_public_rta" {
  subnet_id      = aws_subnet.chat_public_subnet.id
  route_table_id = aws_route_table.chat_public_rt.id
}

# Security Group
resource "aws_security_group" "chat_sg" {
  name_prefix = "chat-app-sg"
  vpc_id      = aws_vpc.chat_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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
    Name = "chat-app-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "chat_server" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.chat_sg.id]
  subnet_id              = aws_subnet.chat_public_subnet.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git
              EOF

  tags = {
    Name = "chat-app-server"
  }
}

# Elastic IP
resource "aws_eip" "chat_eip" {
  instance = aws_instance.chat_server.id
  domain   = "vpc"
  
  tags = {
    Name = "chat-app-eip"
  }
}

# Jenkins Server
resource "aws_instance" "jenkins_server" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.chat_public_subnet.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git java-11-openjdk
              EOF

  tags = {
    Name = "jenkins-server"
  }
}

# Jenkins Security Group
resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg"
  vpc_id      = aws_vpc.chat_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "jenkins-security-group"
  }
}

# Jenkins Elastic IP
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_server.id
  domain   = "vpc"
  
  tags = {
    Name = "jenkins-eip"
  }
}