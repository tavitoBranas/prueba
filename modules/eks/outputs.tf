output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

# Se expone a traves del node group para que quien lo consuma (Helm)
# espere a que haya nodos donde correr pods.
output "node_group_id" {
  value = aws_eks_node_group.this.id
}
