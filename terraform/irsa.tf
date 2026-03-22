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
      Effect = "Allow"
      Action = [
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

resource "null_resource" "annotate_k8sgpt_sa" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}
      kubectl annotate sa k8sgpt-operator-controller-manager \
        -n k8sgpt-operator-system \
        eks.amazonaws.com/role-arn=${aws_iam_role.k8sgpt_bedrock.arn} \
        --overwrite
    EOT
  }
}