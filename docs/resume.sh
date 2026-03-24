#!/bin/bash
set -e

echo "=== Step 1: Terraform Apply ==="
cd terraform
terraform apply -auto-approve

echo "=== Step 2: Update kubeconfig ==="
aws eks update-kubeconfig --region us-east-1 --name eks-aiops-cluster

echo "=== Step 3: Wait for nodes ==="
kubectl wait --for=condition=ready node --all --timeout=300s

echo "=== Step 4: Install cert-manager ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager

echo "=== Step 5: Install K8sGPT Operator ==="
helm repo add k8sgpt https://charts.k8sgpt.ai/ 2>/dev/null || true
helm repo update
helm install k8sgpt-operator k8sgpt/k8sgpt-operator -n k8sgpt-operator-system --create-namespace

echo "=== Step 6: Create Groq Secret ==="
# Replace with your actual Groq key
kubectl create secret generic groq-api-key \
  --from-literal=groq-api-key="${GROQ_API_KEY}" \
  -n k8sgpt-operator-system 2>/dev/null || echo "Secret may already exist"

echo "=== Step 7: Apply K8sGPT CR ==="
kubectl apply -f - << 'EOF'
apiVersion: core.k8sgpt.ai/v1alpha1
kind: K8sGPT
metadata:
  name: k8sgpt-groq
  namespace: k8sgpt-operator-system
spec:
  ai:
    enabled: true
    backend: localai
    model: llama-3.1-8b-instant
    baseUrl: https://api.groq.com/openai/v1
    secret:
      name: groq-api-key
      key: groq-api-key
  noCache: false
  repository: ghcr.io/k8sgpt-ai/k8sgpt
  version: v0.3.48
EOF

echo "=== Step 8: Install ArgoCD ==="
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace

echo "=== Step 9: Install Prometheus + Grafana ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

echo "=== Done! ==="
echo "Check status with:"
echo "  kubectl get pods -A"
echo "  kubectl logs -n k8sgpt-operator-system -l app=k8sgpt-groq --tail=5"


# export GROQ_API_KEY="gsk_your_actual_key"
# chmod +x resume.sh
# ./resume.sh