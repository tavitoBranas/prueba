vpc_name     = "demo-vpc"
cluster_name = "demo-eks"

azs                       = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

kubernetes_version  = "1.35"
node_group_name     = "demo-node-group"
node_instance_types = ["t3.small"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

app_name = "web-app"
