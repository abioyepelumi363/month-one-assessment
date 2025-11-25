# Tell Terraform to use AWS
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get available zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get Amazon Linux 2 image
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 1. CREATE VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "techcorp-vpc"
  }
}

# 2. CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "techcorp-igw"
  }
}

# 3. CREATE PUBLIC SUBNETS
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "techcorp-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "techcorp-public-subnet-2"
  }
}

# 4. CREATE PRIVATE SUBNETS
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "techcorp-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "techcorp-private-subnet-2"
  }
}

# 5. CREATE ELASTIC IPS FOR NAT GATEWAYS
resource "aws_eip" "nat_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  
  tags = {
    Name = "techcorp-nat-eip-1"
  }
}

resource "aws_eip" "nat_2" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  
  tags = {
    Name = "techcorp-nat-eip-2"
  }
}

# 6. CREATE NAT GATEWAYS
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.main]
  
  tags = {
    Name = "techcorp-nat-gateway-1"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  depends_on    = [aws_internet_gateway.main]
  
  tags = {
    Name = "techcorp-nat-gateway-2"
  }
}

# 7. CREATE ROUTE TABLE FOR PUBLIC SUBNETS
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "techcorp-public-rt"
  }
}

# 8. CREATE ROUTE TABLES FOR PRIVATE SUBNETS
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
  
  tags = {
    Name = "techcorp-private-rt-1"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
  
  tags = {
    Name = "techcorp-private-rt-2"
  }
}

# 9. CONNECT ROUTE TABLES TO SUBNETS
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# 10. CREATE BASTION SECURITY GROUP
resource "aws_security_group" "bastion" {
  name        = "techcorp-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "techcorp-bastion-sg"
  }
}

# 11. CREATE WEB SECURITY GROUP
resource "aws_security_group" "web" {
  name        = "techcorp-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
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
    Name = "techcorp-web-sg"
  }
}

# 12. CREATE DATABASE SECURITY GROUP
resource "aws_security_group" "database" {
  name        = "techcorp-database-sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "MySQL from web servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
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
    Name = "techcorp-database-sg"
  }
}

# 13. CREATE BASTION HOST
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_pair_name
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              useradd -m ${var.ssh_username}
              echo "${var.ssh_username}:${var.ssh_password}" | chpasswd
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
              systemctl restart sshd
              echo "${var.ssh_username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${var.ssh_username}
              EOF
  
  tags = {
    Name = "techcorp-bastion-host"
  }
}

# 14. CREATE ELASTIC IP FOR BASTION
resource "aws_eip" "bastion" {
  domain     = "vpc"
  instance   = aws_instance.bastion.id
  depends_on = [aws_internet_gateway.main]
  
  tags = {
    Name = "techcorp-bastion-eip"
  }
}

# 15. CREATE WEB SERVER 1
resource "aws_instance" "web_1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/web_server_setup.sh")
  
  tags = {
    Name = "techcorp-web-server-1"
  }
}

# 16. CREATE WEB SERVER 2
resource "aws_instance" "web_2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.web_instance_type
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/web_server_setup.sh")
  
  tags = {
    Name = "techcorp-web-server-2"
  }
}

# 17. CREATE DATABASE SERVER
resource "aws_instance" "database" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.db_instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = var.key_pair_name
  user_data              = file("${path.module}/user_data/db_server_setup.sh")
  
  tags = {
    Name = "techcorp-database-server"
  }
}

# 18. CREATE APPLICATION LOAD BALANCER
resource "aws_lb" "web" {
  name               = "techcorp-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  
  tags = {
    Name = "techcorp-web-alb"
  }
}

# 19. CREATE TARGET GROUP
resource "aws_lb_target_group" "web" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }
  
  tags = {
    Name = "techcorp-web-tg"
  }
}

# 20. ATTACH WEB SERVERS TO TARGET GROUP
resource "aws_lb_target_group_attachment" "web_1" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

# 21. CREATE LOAD BALANCER LISTENER
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}