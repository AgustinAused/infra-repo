variable "aws_region" {
  default = "us-east-1"
}

variable "ec2_type" {
  default = "t3.micro"
}

variable "ec2_ami" {
  default = "ami-053b0d53c279acc90" # Amazon Linux 2023 us-east-1
}

variable "ec2_public_key" {
  description = "Llave pública SSH para EC2"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  description = "Clave del RDS"
  sensitive   = true
}
