resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes-namespace"       = "kube-system"
            "aws:RequestTag/kubernetes-service-account" = "ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "example-voting-app"
    ManagedBy   = "Terraform"
    Environment = "learning"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role = aws_iam_role.ebs_csi_driver.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}