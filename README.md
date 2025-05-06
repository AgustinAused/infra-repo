# 🧾 Bitácora del Proyecto - Infraestructura como Código y CI/CD en AWS
## 👤 Rol: DevOps Engineer
### Nombre: [Agustin Aused]

## Descripción
Este repositorio contiene ejemplos de cómo implementar infraestructura como código utilizando Terraform y AWS. Se incluyen ejemplos de implementación de una VPC, subredes, instancias EC2 y otros recursos de AWS.

## Requisitos previos
- Tener una cuenta de AWS activa.
- Tener instalado Terraform en tu máquina local.
- Tener configuradas las credenciales de AWS en tu máquina local. Puedes hacerlo utilizando el comando `aws configure` de la CLI de AWS.
- Tener instalado Git en tu máquina local.
- Tener instalado Docker en tu máquina local (opcional, para ejecutar contenedores de prueba).
- Tener instalado Python 3.x en tu máquina local (opcional, para ejecutar scripts de prueba).

---

## 📌 1. Descripción general del proyecto
Desplegar una infraestructura en AWS usando Terraform, integrando dos aplicaciones (frontend en React y backend en Java), con CI/CD automatizado usando GitHub Actions. Además, se incluye un entorno de análisis de código con SonarQube.

---

## 🧱 2. Infraestructura
- **Proveedor**: AWS (cuenta Academy)
- **Herramienta IaC**: Terraform
- **Servicios desplegados**:
  - EC2 con Docker + NGINX
  - RDS Aurora PostgreSQL
  - Security groups + VPC
  - SonarQube (via Docker Compose)

---

## 🔁 3. CI/CD
- **Repositorio Infra**: GitHub con workflows automatizados
- **CI/CD Backend**: Build Maven, Dockerize, Push, Deploy
- **CI/CD Frontend**: Build React, Dockerize, Push, Deploy
- **Workflows divididos** por ambientes/repos
- **Uso de outputs entre jobs (`terraform output`)**
- **Secrets controlados con GH Actions y STS tokens**

---

## 📆 4. Cronología de actividades
| Fecha       | Actividad                                                                 |
|-------------|---------------------------------------------------------------------------|
| 2025-04-10  | Setup inicial de Terraform y diseño de la arquitectura                   |
| 2025-04-11  | EC2 + SG + SSH key + RDS con variables parametrizadas                    |
| 2025-04-12  | Creación de workflows CI/CD para frontend y backend                      |
| 2025-04-13  | SonarQube agregado con Docker Compose                                    |
| 2025-04-14  | Configuración de secrets y automatización STS AWS Academy                |
| 2025-04-15  | Deploy final y testing                                                    |

---

## ⚙️ 5. Herramientas utilizadas
- Terraform v1.8
- AWS CLI
- GitHub Actions
- Docker y Docker Compose
- React (Frontend), Java Spring Boot (Backend)
- SonarQube

---

## 🧩 6. Problemas y soluciones
| Problema                                               | Solución aplicada                                        |
|--------------------------------------------------------|----------------------------------------------------------|
| Error en workflow por mal uso de `${{ secrets }}`      | Corregido formato y estructura YAML                     |
| STS expira cada 36h                                    | Script automático para renovar y subir secrets          |
| Deploy react en EC2 sin dominio                        | Configurado NGINX + reverse proxy                       |
| Output de Terraform no accesible entre jobs            | Usado `outputs:` dentro del job terraform               |

---

## ✅ 7. Resultados
- Infraestructura reproducible
- CI/CD funcional y conectado entre servicios
- Fácil extensión a múltiples entornos (dev, test, prod)
- Uso de mejores prácticas DevOps e IaC

---

## 📎 8. Recursos adicionales
- Repositorio GitHub Infra: [link]
- Repositorio Front: [link]
- Repositorio Backend: [link]
- Documento de arquitectura (opcional)

