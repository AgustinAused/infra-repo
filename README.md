# infra-repo
 En este repositorio se va a encontrar el codigo para desplegar la infraescructura como codigo con Terraform y AWS

# Infraestructura como código con Terraform y AWS

## Descripción
Este repositorio contiene ejemplos de cómo implementar infraestructura como código utilizando Terraform y AWS. Se incluyen ejemplos de implementación de una VPC, subredes, instancias EC2 y otros recursos de AWS.

## Requisitos previos
- Tener una cuenta de AWS activa.
- Tener instalado Terraform en tu máquina local.
- Tener configuradas las credenciales de AWS en tu máquina local. Puedes hacerlo utilizando el comando `aws configure` de la CLI de AWS.
- Tener instalado Git en tu máquina local.
- Tener instalado Docker en tu máquina local (opcional, para ejecutar contenedores de prueba).
- Tener instalado Python 3.x en tu máquina local (opcional, para ejecutar scripts de prueba).

## Estructura del repositorio
```
infra-repo/
├── README.md
├── EC2 y RDS/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
