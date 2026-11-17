data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "networking" {
  source             = "../modules/networking"
  vpc_name           = var.vpc_name
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnet_cidr_blocks
  availability_zones = var.azs
  cluster_name       = var.cluster_name
}

module "eks" {
  source             = "../modules/eks"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  cluster_role_arn   = data.aws_iam_role.labrole.arn
  node_role_arn      = data.aws_iam_role.labrole.arn
  subnet_ids         = module.networking.public_subnet_ids
  node_group_name    = var.node_group_name
  instance_types     = var.node_instance_types
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size

  # Las rutas a internet deben existir antes de que los nodos intenten unirse
  # al cluster, y seguir existiendo mientras se destruyen.
  depends_on = [module.networking]
}

module "alb_controller" {
  source       = "../modules/alb_controller"
  cluster_name = module.eks.cluster_name
  aws_region   = var.aws_region
  vpc_id       = module.networking.vpc_id

  # El controller necesita nodos donde correr.
  depends_on = [module.eks]
}

module "ecr" {
  source = "../modules/ecr"
  name   = var.app_name
}
