# Configuración del Proveedor AWS
provider "aws" {
  region = var.aws_region  # Usa la variable de región definida en variables.tf
}

# Creación de VPC (Red Privada Virtual)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Rango IP grande para toda la red
  tags = {
    Name = "Main-VPC"
  }
}

# Data Source para obtener Zonas de Disponibilidad
data "aws_availability_zones" "available" {
  state = "available"  # Solo considera AZs habilitadas en tu cuenta
}

# ---------------------------
# SUBNETS PÚBLICAS (Para EC2)
# ---------------------------

# Subred Pública en AZ1
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # Rango IP específico para esta subred
  availability_zone       = data.aws_availability_zones.available.names[0]  # Ej: us-east-1a
  map_public_ip_on_launch = true  # Asigna IP pública automáticamente
  tags = {
    Name = "Public-Subnet-AZ1"
  }
}

# Subred Pública en AZ2 (Para alta disponibilidad)
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]  # Ej: us-east-1b
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-AZ2"
  }
}

# ---------------------------
# SUBNETS PRIVADAS (Para RDS)
# ---------------------------

# Subred Privada en AZ1
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Private-Subnet-AZ1"
  }
}

# Subred Privada en AZ2
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Private-Subnet-AZ2"
  }
}

# ---------------------------
# GRUPOS DE SEGURIDAD
# ---------------------------

# Security Group para EC2 (Acceso público)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Permite SSH, HTTP, HTTPS y puertos personalizados"
  vpc_id      = aws_vpc.main.id

  # Regla SSH (¡restringir en producción!)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Considerar usar una IP específica
  }

  # Regla HTTP
  ingress {
    from_port   = 80
    to_port     = 80 # Mejor práctica: separar de 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nuevo: Regla HTTPS agregada
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla personalizada (mantenemos 9000)
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para RDS (Acceso privado)
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Permite acceso solo desde el EC2"
  vpc_id      = aws_vpc.main.id

  # Solo permite conexiones PostgreSQL desde el SG de EC2
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]  # Referencia al SG de EC2
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# EC2 - SERVIDOR DE APLICACIONES
# ---------------------------

# Par de claves SSH
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ec2_public_key  # Llave pública desde variables
}

# Instancia EC2
resource "aws_instance" "app_server" {
  ami           = var.ec2_ami  # AMI desde variables (ej: Amazon Linux 2)
  instance_type = var.ec2_type
  subnet_id     = aws_subnet.public_az1.id  # Se despliega en subred pública

  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true  # IP pública accesible desde internet

  # Script de inicialización (debe existir en tu directorio)
  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name = "Application-Server"
  }
}

# ---------------------------
# RDS - BASE DE DATOS AURORA
# ---------------------------

# Grupo de Subredes para Aurora
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]  # 2 AZs

  tags = {
    Name = "Aurora-Subnet-Group"
  }
}

# Cluster Aurora PostgreSQL
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  master_username         = var.db_username  # Desde variables
  master_password         = var.db_password  # Desde variables
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]  # SG dedicado
  skip_final_snapshot     = true  # ¡En producción usar false y hacer backups!
}

# Instancia de Base de Datos
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier          = "aurora-instance-01"
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = "db.t3.medium"  # Tipo de instancia
  engine              = aws_rds_cluster.aurora.engine
  publicly_accessible = false  # ¡Importante para seguridad!

  tags = {
    Name = "Aurora-DB-Instance"
  }
}