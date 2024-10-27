variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mykubernetes"
}

variable "subnet_ids" {
  description = "IDs of the subnets"
  type        = list(string)
  default     = ["subnet-06b5cdc561fec910b", "subnet-08e5f35680b5df800"]
}

variable "role_arn" {
  description = "ARN of the IAM role for EKS"
  type        = string
  default     = "arn:aws:iam::417738508223:role/LabRole"
}