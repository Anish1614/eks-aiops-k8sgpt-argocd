resource "aws_iam_role" "k8sgpt_bedrock" {
  name = "${var.cluster_name}-k8sgpt-bedrock-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:k8sgpt-operator-system:*"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "k8sgpt_bedrock" {
  role = aws_iam_role.k8sgpt_bedrock.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:GetFoundationModel",
        "bedrock:GetInferenceProfile"
      ]
      Resource = "*"
    }]
  })
}
resource "aws_iam_role" "argocd_irsa" {
  name = "${var.cluster_name}-argocd-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:argocd:*"
        }
      }
    }]
  })
}


resource "kubernetes_service_account_v1" "k8sgpt_bedrock" {
  metadata {
    name      = "k8sgpt-bedrock"
    namespace = "k8sgpt-operator-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.k8sgpt_bedrock.arn
    }
  }
}