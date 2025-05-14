#!/bin/bash

# CONFIG: Reemplazá esto con tu instancia temporal (donde instalás el nuevo backend)
INSTANCE_ID="ami-053b0d53c279acc90"
NEW_AMI_NAME="backend-$(date +%Y%m%d%H%M%S)"

echo "🛠️  Creando nueva AMI: $NEW_AMI_NAME desde instancia $INSTANCE_ID..."

# 1. Crear nueva AMI
AMI_ID=$(aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name "$NEW_AMI_NAME" \
  --description "Backend AMI generated on $(date)" \
  --no-reboot \
  --output text)

echo "✅ AMI creada: $AMI_ID"

# 2. Esperar a que esté 'available'
echo "⏳ Esperando que AMI esté disponible..."
aws ec2 wait image-available --image-ids $AMI_ID
echo "✅ AMI disponible para usar"

# 3. Actualizar terraform.tfvars con la nueva AMI
echo "📝 Reemplazando AMI en terraform.tfvars..."
sed -i.bak -E "s|backend_ami_id *= *\"ami-[a-zA-Z0-9]+\"|backend_ami_id = \"$AMI_ID\"|" terraform.tfvars

# 4. Aplicar los cambios con Terraform
echo "🚀 Ejecutando terraform apply..."
terraform apply -auto-approve

echo "🎉 Despliegue masivo completo con AMI: $AMI_ID"
