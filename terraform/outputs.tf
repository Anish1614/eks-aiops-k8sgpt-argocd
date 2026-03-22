output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group IDs attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "kubectl_config_command" {
  description = "Command to update local kubeconfig for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "allowed_public_ip" {
  description = "The public IP address currently allowed to access the EKS cluster endpoint"
  value       = chomp(data.http.myip.response_body)
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}



output "node_group_iam_role_arn" {
  description = "IAM Role ARN for EKS Node Group"
  value       = module.eks.eks_managed_node_groups["default"].iam_role_arn
}
output "argocd_iam_role_arn" {
  value = aws_iam_role.argocd_irsa.arn
}