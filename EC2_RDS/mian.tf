provider "aws" {
  region = var.aws_region

}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH, HTTP and custom ports"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ec2_public_key
}

resource "aws_instance" "app_server" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.allow_ssh_http.name]
  associate_public_ip_address = true

  user_data              = file("ec2-user-data.sh")

  tags = {
    Name = "AppServer"
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.public.id]
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.allow_ssh_http.id]
  skip_final_snapshot     = true
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier              = "aurora-cluster-instance"
  cluster_identifier      = aws_rds_cluster.aurora.id
  instance_class          = "db.t3.medium"
  engine                  = aws_rds_cluster.aurora.engine
  publicly_accessible     = true
}
