resource "aws_iam_role" "k8sgpt_bedrock" {
  name = "k8sgpt-bedrock-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:k8sgpt-operator-system:k8sgpt-operator"
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
      Action   = ["bedrock:InvokeModel"]
      Resource = "arn:aws:bedrock:ap-south-1::foundation-model/amazon.titan-text-lite-v1"
    }]
  })
}
