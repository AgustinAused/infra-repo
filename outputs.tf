# ----------------------------------------
# Outputs útiles - DNS, endpoints y nombres
# ----------------------------------------

output "alb_dns" {
  description = "DNS del ALB"
  value       = aws_lb.backend.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de RDS"
  value       = aws_rds_cluster.aurora.endpoint
}

output "asg_name" {
  value = aws_autoscaling_group.backend_asg.name
}

output "sonarqube_ip" {
  value = aws_instance.sonarqube.public_ip
}