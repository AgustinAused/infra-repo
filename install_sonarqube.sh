#!/bin/bash
set -e

# Configuración inicial
SONAR_VERSION="${SONAR_VERSION}"
SONAR_DIR="/opt/sonarqube"
SONAR_USER="sonarqube"
SONAR_DB_USER="sonar"
SONAR_DB_PASSWORD="${db_password}"
SONAR_DB_HOST="${db_endpoint}"
SONAR_DB_NAME="sonarqube"

# 1. Instalar dependencias
yum update -y
amazon-linux-extras enable epel
yum install -y java-11-amazon-corretto-devel unzip

# 2. Crear usuario dedicado
if ! id -u $SONAR_USER >/dev/null 2>&1; then
  useradd -d $SONAR_DIR -s /bin/bash $SONAR_USER
fi

# 3. Descargar SonarQube
for i in {1..3}; do
  wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip && break
  sleep 10
done

# 4. Descomprimir y configurar permisos
unzip -q sonarqube-${SONAR_VERSION}.zip -d $SONAR_DIR
mv $SONAR_DIR/sonarqube-${SONAR_VERSION}/* $SONAR_DIR
rm -rf sonarqube-${SONAR_VERSION}.zip $SONAR_DIR/sonarqube-${SONAR_VERSION}

# 5. Esperar a que RDS esté disponible
until nc -zv $SONAR_DB_HOST 5432; do
  echo "Esperando a PostgreSQL..."
  sleep 30
done

# 6. Configurar sonar.properties
cat > $SONAR_DIR/conf/sonar.properties <<EOF
sonar.jdbc.username=$SONAR_DB_USER
sonar.jdbc.password=$SONAR_DB_PASSWORD
sonar.jdbc.url=jdbc:postgresql://$SONAR_DB_HOST/$SONAR_DB_NAME
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+UseG1GC
sonar.search.javaAdditionalOpts=-Dbootstrap.system_call_filter=false
EOF
chmod 600 $SONAR_DIR/conf/sonar.properties

# 7. Configurar systemd service
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube Service
After=syslog.target network.target

[Service]
Type=simple
User=$SONAR_USER
Group=$SONAR_USER
Environment="SONAR_JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto.x86_64"
ExecStart=$SONAR_DIR/bin/linux-x86-64/sonar.sh start
ExecStop=$SONAR_DIR/bin/linux-x86-64/sonar.sh stop
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
LimitMEMLOCK=16384

[Install]
WantedBy=multi-user.target
EOF

# 8. Ajustar permisos e iniciar servicio
chown -R $SONAR_USER:$SONAR_USER $SONAR_DIR
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

# 9. Verificar estado
for i in {1..30}; do
  if systemctl is-active --quiet sonarqube; then
    echo "SonarQube está activo."
    break
  fi
  sleep 10
done

curl -sI http://localhost:9000 | grep "200 OK"