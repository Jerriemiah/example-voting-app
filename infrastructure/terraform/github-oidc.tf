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
      values   = ["repo:<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>:ref:refs/heads/master"]
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
