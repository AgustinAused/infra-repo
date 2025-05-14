# --------------------------------------------
# EC2 SonarQube - Análisis de código CI/CD
# --------------------------------------------
resource "aws_instance" "sonarqube" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = "t3.medium"
  key_name      = var.key_pair_name
  subnet_id     = aws_subnet.public_az1.id
  vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]

  user_data = base64encode(templatefile("install_sonarqube.sh", {
    DB_PASSWORD  = var.db_password  
  }))

  tags = {
    Name = "SonarQube-Server"
  }
}

# ----------------------------------------------
# SG SonarQube - Puerto 9000 y SSH autorizado
# ----------------------------------------------
resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-sg"
  description = "Permite acceso a SonarQube"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restringir a tu IP en producción
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}