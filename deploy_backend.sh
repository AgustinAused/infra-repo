#!/bin/bash
set -euo pipefail

INSTANCE_ID=${INSTANCE_ID:-""}
NEW_AMI_NAME="backend-$(date +%Y%m%d%H%M%S)"

if [[ -z "$INSTANCE_ID" ]]; then
  echo "❌ INSTANCE_ID no está definido. Definilo como variable de entorno o parámetro."
  exit 1
fi

echo "🛠️  Creando nueva AMI: $NEW_AMI_NAME desde instancia $INSTANCE_ID..."

# 1. Crear nueva AMI
AMI_ID=$(aws ec2 create-image \
  --instance-id "$INSTANCE_ID" \
  --name "$NEW_AMI_NAME" \
  --description "Backend AMI generated on $(date)" \
  --no-reboot \
  --output text)

echo "✅ AMI creada: $AMI_ID"

# 2. Esperar a que esté disponible
echo "⏳ Esperando que la AMI esté disponible..."
aws ec2 wait image-available --image-ids "$AMI_ID"
echo "✅ AMI disponible."

# 3. Actualizar terraform.tfvars
echo "📝 Actualizando AMI en terraform.tfvars..."
sed -i.bak -E "s|backend_ami_id *= *\"ami-[a-zA-Z0-9]+\"|backend_ami_id = \"$AMI_ID\"|" terraform.tfvars

# 4. Aplicar Terraform
echo "🚀 Ejecutando terraform apply..."
terraform init
terraform apply -auto-approve

echo "🎉 Infraestructura actualizada con nueva AMI: $AMI_ID"

