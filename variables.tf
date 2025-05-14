variable "aws_region" {
  default = "us-east-1"
}

variable "backend_ami_id" {
  description = "AMI del backend"
  type        = string
}

variable "key_pair_name" {
  description = "Nombre del par de claves SSH"
  type        = string
}

variable "ec2_type" {
  default = "t3.micro"
}

variable "desired_capacity" {
  default = 2
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 4
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "ec2_public_key" {
  description = "Llave pública SSH"
  type        = string
}

variable "my_ip" {
  description = "Tu IP para acceso SSH (formato CIDR)"
  type        = string
  default     = "0.0.0.0/0"  # ¡Cambia esto en producción!
}

variable "sonarqube_version" {
  description = "Versión de SonarQube a instalar"
  type        = string
  default     = "9.9.2.77730"  # Versión LTS recomendada
}