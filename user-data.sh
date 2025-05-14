#!/bin/bash
# user-data.sh (actualizado)
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Descargar JAR desde S3 (ejemplo)
aws s3 cp "s3://my-bucket/backend.jar" /home/ec2-user/backend.jar

# Variables de entorno para RDS
echo "DB_ENDPOINT=${db_endpoint}" > /home/ec2-user/.env
echo "DB_USER=${db_user}" >> /home/ec2-user/.env
echo "DB_PASSWORD=${db_password}" >> /home/ec2-user/.env

# Ejecutar la app
docker run -d -p 8080:8080 --env-file /home/ec2-user/.env myapp:latest