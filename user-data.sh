#!/bin/bash

# Actualizar paquetes
yum update -y

# Habilitar extras de Amazon y Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user  # Permitir que ec2-user use Docker

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Crear carpeta para los servicios
mkdir -p /home/ec2-user/sonarqube
cd /home/ec2-user/sonarqube

# Crear el archivo docker-compose.yml para SonarQube
cat > docker-compose.yml <<EOF
version: "3"
services:
  sonarqube:
    image: sonarqube:lts
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
EOF

# Ejecutar SonarQube en background
docker-compose up -d

# Esperar a que SonarQube esté levantado
until $(curl --output /dev/null --silent --head --fail http://localhost:9000); do
    echo "Esperando que SonarQube esté listo..."
    sleep 5
done
echo "✅ SonarQube está corriendo en http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"

# Instalar herramientas adicionales
yum install -y aws-cli jq git maven java-1.8.0-openjdk-devel

# Instalar Node.js 22 y npm
curl -sL https://rpm.nodesource.com/setup_22.x | bash -
yum install -y nodejs
npm install -g npm

# Crear carpetas para frontend y backend
mkdir -p /home/ec2-user/frontend
mkdir -p /home/ec2-user/backend
chown -R ec2-user:ec2-user /home/ec2-user

echo "🎉 EC2 lista para deployar backend y frontend automáticamente."
