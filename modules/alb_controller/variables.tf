variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC del cluster"
  type        = string
}
