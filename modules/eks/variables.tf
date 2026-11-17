variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN del IAM role del control plane"
  type        = string
}

variable "node_role_arn" {
  description = "ARN del IAM role de los nodos"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets del cluster y de los nodos"
  type        = list(string)
}

variable "node_group_name" {
  description = "Nombre del managed node group"
  type        = string
}

variable "instance_types" {
  description = "Tipos de instancia de los nodos"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "network_dependencies" {
  description = "IDs de recursos de red que deben existir antes que los nodos"
  type        = list(string)
  default     = []
}
