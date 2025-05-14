# Configuración del Proveedor AWS
provider "aws" {
  region = var.aws_region
}

# Creación de VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Main-VPC"
  }
}

# Zonas de Disponibilidad
data "aws_availability_zones" "available" {
  state = "available"
}



# Subredes Públicas
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-AZ1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-AZ2"
  }
}

# Subredes Privadas
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Private-Subnet-AZ1"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Private-Subnet-AZ2"
  }
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"  # Nombre de la clave
  public_key = file("~/.ssh/id_rsa.pub")  # Ruta a tu clave pública local
}

# Security Group para ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite trafico HTTP/HTTPS al ALB"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "backend" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

# Target Group para el backend
resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 8080  # Puerto de tu aplicación
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/actuator/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener del ALB
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Security Group para EC2 (solo permite tráfico del ALB)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Permite trafico del ALB y SSH restringido"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080  # Puerto de la aplicación
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # Solo desde el ALB
  }

  ingress {
    from_port   = 22  # SSH restringido a tu IP
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ej: "200.100.50.25/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# SECURITY GROUP PARA RDS
# ---------------------------

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Permite acceso solo desde el EC2"
  vpc_id      = aws_vpc.main.id

  # Solo permite conexiones PostgreSQL desde el SG de EC2
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id, aws_security_group.sonarqube_sg.id]  # Referencia al SG de EC2 y sonarqube
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [aws_security_group.ec2_sg]
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


# Recursos de VPC Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Main-IGW"
  }
}

# Tabla de rutas para las subredes públicas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-RouteTable"
  }
}

# Asociar subredes públicas a la tabla de rutas
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}