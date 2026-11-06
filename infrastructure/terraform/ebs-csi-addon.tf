resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  addon_version = "v1.67.2-eksbuild.1"

  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi_driver.arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [
    module.eks,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}