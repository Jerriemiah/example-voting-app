variable "aws_region" {
  description = "AWS region in which to create the EKS cluster"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "voting-app"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "node_instance_type" {
  description = "EC2 instance type for managed node group"
  type        = string
  default     = "t3.small"
}

variable "desired_size" {
  description = "Desired managed node count"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum managed node count"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum managed node count"
  type        = number
  default     = 2
}

variable "allowed_admin_cidr" {
  description = "CIDR allowed to access the voting app NodePorts during testing"
  type        = string
}