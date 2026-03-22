# irsa.tf - Simplified for OpenAI backend

# Only IRSA role needed is for ArgoCD (if ArgoCD needs AWS access)
# If ArgoCD is only syncing from GitHub, you might not even need this
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
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:argocd:argocd-application-controller"
        }
      }
    }]
  })
}

# Optional: If ArgoCD needs to manage AWS resources (Secrets Manager, etc.)
# resource "aws_iam_role_policy" "argocd_policy" {
#   role = aws_iam_role.argocd_irsa.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "secretsmanager:GetSecretValue"
#       ]
#       Resource = "*"
#     }]
#   })
# }

