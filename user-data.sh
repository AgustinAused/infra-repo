#!/bin/bash
set -e

# Variables injectadas por Terraform via templatefile()
DB_ENDPOINT=${db_endpoint}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DOMAIN=${url}

# 1. Actualización del sistema y Docker
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# 2. Instalar AWS CLI (para acceso a S3)
yum install -y aws-cli

# 3. Descargar JAR desde S3 (debe existir el objeto backend.jar)
aws s3 cp "s3://my-bucket/backend.jar" /home/ec2-user/backend.jar
chmod +x /home/ec2-user/backend.jar

# 4. Crear archivo .env con variables sensibles
cat <<EOF > /home/ec2-user/.env
DB_ENDPOINT=${DB_ENDPOINT}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF

# 5. Crear archivo de unidad systemd para la app
cat <<EOL > /etc/systemd/system/myapp.service
[Unit]
Description=MyApp Backend Service
After=docker.service
Requires=docker.service

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/docker run --name myapp --env-file /home/ec2-user/.env -p 8080:8080 myapp:latest
ExecStop=/usr/bin/docker stop myapp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# 6. Activar el servicio
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable myapp
systemctl start myapp

# 7. Certbot: modo standalone (no requiere NGINX)
yum install -y certbot

certbot certonly --standalone \
  --preferred-challenges http \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --non-interactive --agree-tos \
  --email your@email.com || echo "Certbot falló, pero la app sigue funcionando."

echo "✅ Configuración finalizada: backend en ejecución en 8080"
