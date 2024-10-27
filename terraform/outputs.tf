output "cluster_endpoint" {
  description = "The EKS cluster endpoint"
  value       = aws_eks_cluster.my_cluster.endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.my_cluster.name
}

output "cluster_role_arn" {
  description = "The IAM role ARN of the EKS cluster"
  value       = aws_eks_cluster.my_cluster.role_arn
}
