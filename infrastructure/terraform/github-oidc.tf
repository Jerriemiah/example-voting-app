resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Jerriemiah/example-voting-app:ref:refs/heads/master"]
    }
  }
}

resource "aws_iam_role" "github_actions_eks_deploy" {
  name               = "example-voting-app-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

data "aws_iam_policy_document" "github_actions_eks_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi"
    ]
    resources = [
      "arn:aws:eks:eu-north-1:480227945624:cluster/voting-app"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_eks_deploy" {
  name   = "eks-deploy-access"
  role   = aws_iam_role.github_actions_eks_deploy.id
  policy = data.aws_iam_policy_document.github_actions_eks_deploy.json
}

module "github_actions_access_entry" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  count  = 0
}

# Grant the GitHub Actions IAM role administrative access to the EKS cluster
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_role.github_actions_eks_deploy.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.github_actions_eks_deploy.arn

  access_scope {
    type = "cluster"
  }

  # Ensure the access entry is fully registered before associating the policy
  depends_on = [aws_eks_access_entry.github_actions]
}