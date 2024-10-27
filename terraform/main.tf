provider "aws" {
  region = var.aws_region
}

# EKS Cluster
resource "aws_eks_cluster" "my_cluster" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids         = var.subnet_ids
  }
}

# EKS Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "noeud1"
  node_role_arn   = var.role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}

# Add a rule to allow all traffic on port 30000 in the default security group created by the EKS cluster
resource "aws_security_group_rule" "allow_port_30000" {
  security_group_id = aws_eks_cluster.my_cluster.vpc_config.0.security_group_ids.0
  type              = "ingress"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}


