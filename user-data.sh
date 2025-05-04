#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Instalar docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Crear carpeta para sonar
mkdir -p /home/ec2-user/sonarqube
cd /home/ec2-user/sonarqube

# Copiar docker-compose desde metadata (o podés usar curl/git/s3)
cat <<EOF > docker-compose.yml
$(cat docker-compose-sonarqube.yml)
EOF

docker-compose up -d
# Esperar a que el contenedor de SonarQube esté listo
until $(curl --output /dev/null --silent --head --fail http://localhost:9000); do
    printf '.'
    sleep 5
done
echo "SonarQube is up and running!"
# Instalar AWS CLI
yum install -y aws-cli
# Instalar jq
yum install -y jq
# Instalar git
yum install -y git