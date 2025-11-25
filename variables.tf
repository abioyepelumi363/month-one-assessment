variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "admin_ip" {
  description = "Your IP address with /32"
  type        = string
}

variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "techcorpuser"
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  sensitive   = true
}