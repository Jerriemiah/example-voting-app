module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access  = true
  endpoint_private_access = true

  endpoint_public_access_cidrs = [
    "0.0.0.0/0"
  ]

  vpc_id = data.aws_vpc.default.id

  subnet_ids = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id
  ]

  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      name = "${var.cluster_name}-nodes"

      instance_types = [var.node_instance_type]

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      ami_type = "AL2023_x86_64_STANDARD"

      labels = {
        workload = "general"
      }
    }
  }

  tags = {
    Project     = "example-voting-app"
    ManagedBy   = "Terraform"
    Environment = "learning"
  }
}