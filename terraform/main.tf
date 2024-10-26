provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr  # Using the variable for the CIDR
}

# Create the EKS Cluster
resource "aws_eks_cluster" "my_cluster" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = "1.30"

  vpc_config {
    subnet_ids         = var.subnet_ids
    // Do not specify security_group_ids; let EKS use the default SG
  }
}

# Create the Node Group
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

# Data source to fetch the default security group for the EKS cluster
data "aws_eks_cluster" "my_cluster_data" {
  name = aws_eks_cluster.my_cluster.name
}

data "aws_security_group" "eks_cluster_sg" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.my_vpc.id]
  }

  filter {
    name   = "group-name"
    values = ["eks-cluster-${data.aws_eks_cluster.my_cluster_data.id}"]  # Using cluster ID to find the SG
  }
}

# Security Group Rule to Allow Ingress Traffic on Port 30000
resource "aws_security_group_rule" "allow_ingress_30000" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  security_group_id = data.aws_security_group.eks_cluster_sg.id  # Use the ID of the EKS cluster SG
  cidr_blocks       = ["0.0.0.0/0"]  # Allow traffic from anywhere
}

# Security Group Rule to Allow Egress Traffic on Port 30000
resource "aws_security_group_rule" "allow_egress_30000" {
  type              = "egress"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  security_group_id = data.aws_security_group.eks_cluster_sg.id  # Use the ID of the EKS cluster SG
  cidr_blocks       = ["0.0.0.0/0"]  # Allow traffic to anywhere
}
