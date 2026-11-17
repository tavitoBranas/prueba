variable "aws_region" {
  description = "Región para desplegar la infra"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "El nombre de la VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "El bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "Los bloques CIDR para las subredes públicas"
  type        = list(string)
}

variable "azs" {
  description = "Las zonas de disponibilidad para la VPC"
  type        = list(string)
}

variable "cluster_name" {
  description = "El nombre del cluster EKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes del cluster"
  type        = string
  default     = "1.35"
}

variable "node_group_name" {
  description = "El nombre del managed node group"
  type        = string
}

variable "node_instance_types" {
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

variable "app_name" {
  description = "Nombre de la aplicación (y del repositorio ECR)"
  type        = string
  default     = "web-app"
}
