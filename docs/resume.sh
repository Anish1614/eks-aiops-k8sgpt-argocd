#!/bin/bash
set -e

echo "=== Step 1: Terraform Apply ==="
# cd /mnt/c/Users/anish/Desktop/project/eks-aiops-k8sgpt-argocd/eks-aiops-k8sgpt-argocd/terraform
# terraform apply -auto-approve

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
kubectl apply -f /mnt/c/Users/anish/Desktop/project/eks-aiops-k8sgpt-argocd/eks-aiops-k8sgpt-argocd/helm/k8sgpt/active/k8sgpt-groq.yaml

echo "=== Step 8: Install ArgoCD ==="
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace

echo "=== Step 9: Install Prometheus + Grafana ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

echo "=== Step 10: Enable K8sGPT Metrics & Dashboard ==="
helm upgrade k8sgpt-operator k8sgpt/k8sgpt-operator \
  -n k8sgpt-operator-system \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.additionalLabels.release=kube-prometheus-stack \
  --set grafanaDashboard.enabled=true

echo "=== Done! ==="
echo "Check status with:"
echo "  kubectl get pods -A"
echo "  kubectl logs -n k8sgpt-operator-system -l app=k8sgpt-groq --tail=5"


# export GROQ_API_KEY="gsk_your_actual_key"
# chmod +x resume.sh
# ./resume.sh