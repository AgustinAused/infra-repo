#!/bin/bash
set -e

# Variables inyectadas por Terraform
DB_PASSWORD="${DB_PASSWORD}"

# 1. Instalar PostgreSQL
yum install -y postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql

# 2. Configurar contraseña del superusuario 'postgres' y crear rol/DB para SonarQube
sudo -u postgres psql <<EOSQL
ALTER USER postgres WITH PASSWORD '${DB_PASSWORD}';
CREATE USER sonar WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE sonarqube OWNER sonar;
EOSQL

# 3. Ajustar pg_hba.conf para forzar md5 en conexiones TCP locales
pg_hba=/var/lib/pgsql/data/pg_hba.conf

# Local IPv4
sudo sed -i -E \
  "s#^(host\s+all\s+all\s+127\.0\.0\.1/32\s+)ident#\1md5#;" \
  $${pg_hba}
# Local IPv6
sudo sed -i -E \
  "s#^(host\s+all\s+all\s+::1/128\s+)ident#\1md5#;" \
  $${pg_hba}

# Reiniciar para aplicar cambios
systemctl reload postgresql

# 4. Instalar Docker y Docker Compose
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 5. Ajustar configuración de kernel para Elasticsearch
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# 6. Crear docker-compose.yml para SonarQube usando BD local
cat > /home/ec2-user/docker-compose.yml <<EOF

services:
  db:
    image: postgres:15
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - sonar_net

  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
    networks:
      - sonar_net
    restart: unless-stopped

volumes:
  db_data:
  sonarqube_data:
  sonarqube_extensions:

networks:
  sonar_net:
    driver: bridge
EOF

chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

# 7. Iniciar SonarQube
sudo -u ec2-user docker-compose -f /home/ec2-user/docker-compose.yml up -d

echo "⏳ Esperando que SonarQube inicie..."
sleep 30
docker ps | grep sonarqube || echo "El contenedor SonarQube no está corriendo"
curl -sI http://localhost:9000 | grep "200 OK" || echo "SonarQube aún no responde en el puerto 9000"
echo "✅ SonarQube debería estar corriendo en http://localhost:9000"
