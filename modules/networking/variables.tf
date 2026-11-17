variable "vpc_name" {
  description = "Nombre de la VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de CIDRs de subnets públicas"
  type        = list(string)
}

variable "availability_zones" {
  description = "Zonas de disponibilidad"
  type        = list(string)
}

variable "cluster_name" {
  description = "Nombre del cluster EKS (para el tag kubernetes.io/cluster/<nombre>)"
  type        = string
}
