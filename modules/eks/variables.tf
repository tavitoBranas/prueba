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
  description = "Cantidad deseada de nodos"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Cantidad mínima de nodos"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Cantidad máxima de nodos"
  type        = number
  default     = 3
}
