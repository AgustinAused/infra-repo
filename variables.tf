variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ec2_public_key" {
  description = "EC2 public key"
  type        = string
}

variable "ec2_ami" {
  description = "EC2 AMI ID"
  type        = string
}

variable "ec2_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}