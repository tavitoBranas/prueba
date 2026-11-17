output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = module.ecr.repository_url
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ingress_hostname_command" {
  description = "DNS del ALB creado por el Ingress de la app (disponible ~2 min después del primer deploy)"
  value       = "kubectl get ingress ${var.app_name} -n ${var.app_name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
