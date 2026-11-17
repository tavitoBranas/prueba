# AWS Load Balancer Controller: cada Ingress con ingressClassName "alb"
# genera un Application Load Balancer.
#
# AWS Academy: no se crean roles IAM ni OIDC provider. El controller toma las
# credenciales de LabRole (rol de los nodos) via IMDS.
resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # WAF y Shield no estan disponibles en el lab.
  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  depends_on = [terraform_data.nodes_ready]
}

# El controller necesita nodos donde correr.
resource "terraform_data" "nodes_ready" {
  input = var.node_group_id
}
