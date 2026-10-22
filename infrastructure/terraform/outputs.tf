output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS control-plane endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_region" {
  description = "AWS region containing the cluster"
  value       = var.aws_region
}

output "cluster_security_group_id" {
  description = "EKS control-plane security group ID"
  value       = module.eks.cluster_security_group_id
}

output "default_vpc_id" {
  description = "Default VPC used by this cluster"
  value       = data.aws_vpc.default.id
}

#output "selected_subnet_ids" {
#  description = "Default VPC subnet IDs supplied to EKS"
#  value       = local.eks_subnet_ids
#}
output "selected_subnet_ids" {
  description = "Terraform-managed default VPC subnet IDs supplied to EKS"
  value = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id,
  ]
}