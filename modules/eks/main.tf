resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  tags = {
    Name = var.cluster_name
  }
}

# AL2023 deja el hop limit de IMDS en 1, lo que impide que los pods lean las
# credenciales del nodo. En AWS Academy no se puede usar IRSA ni Pod Identity
# (no se pueden crear roles IAM), asi que el AWS Load Balancer Controller usa
# las credenciales de LabRole del nodo via IMDS: se necesita hop limit 2.
resource "aws_launch_template" "nodes" {
  name_prefix = "${var.node_group_name}-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.node_group_name
    }
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  tags = {
    Name = var.node_group_name
  }

  # Las rutas a internet deben existir antes de que los nodos intenten unirse
  # al cluster, y seguir existiendo mientras se destruyen.
  depends_on = [terraform_data.network_ready]
}

# Ancla para propagar la dependencia sobre las rutas del modulo networking.
resource "terraform_data" "network_ready" {
  input = var.network_dependencies
}
