# project description
Project: EKS AIOps Stack — K8sGPT + ArgoCD + Amazon Bedrock
What this project does:

Deploys an AI-powered Kubernetes operations platform on AWS EKS where K8sGPT continuously analyzes the cluster, detects issues (crashlooping pods, OOM, misconfigs, failed deployments), and uses Amazon Bedrock (Claude 3.5 Haiku) as the AI backend to generate human-readable diagnosis and fix suggestions — all without any GPU or OpenAI dependency
Wires the AI findings into a GitOps loop via ArgoCD, so K8sGPT analysis results can trigger automated PRs/syncs rather than just sitting in logs
Sets up full observability via Prometheus + Grafana so cluster health, K8sGPT scan results, and Bedrock invocation metrics are all visible on dashboards
Phase 3 adds autonomous remediation — Alertmanager fires a webhook on alert → triggers K8sGPT scan → human reviews the git PR

Tech stack used:

Infrastructure — AWS EKS (us-east-1), Terraform, public subnets (cost-optimized), IRSA for zero-secret auth
AI layer — K8sGPT Operator (CNCF project), Amazon Bedrock (Claude 3.5 Haiku via cross-region inference profile)
GitOps — ArgoCD syncing from your GitHub repo
Observability — kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
Phase 3 — KEDA (event-driven autoscaling), Alertmanager webhook → K8sGPT trigger, CloudWatch audit trail

What gets installed via Helm (in order):

cert-manager — required dependency for K8sGPT Operator CRDs
k8sgpt-operator — core AI diagnostics engine
kube-prometheus-stack — Prometheus + Grafana + Alertmanager
argo-cd — GitOps engine
--------------------------------------------------------------------------------------------------------------
eks-aiops-k8sgpt-argocd/
├── terraform/
│   ├── main.tf              # providers, backend
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf               # VPC + subnets (module)
│   ├── eks.tf               # EKS cluster + managed node group
│   ├── irsa.tf              # IRSA role for K8sGPT → Bedrock
│   ├── addons.tf            # EBS CSI, CoreDNS, kube-proxy
│   └── terraform.tfvars
├── helm/
│   ├── k8sgpt/
│   │   └── values.yaml      # Bedrock backend config
│   ├── argocd/
│   │   └── values.yaml
│   └── kube-prometheus-stack/
│       └── values.yaml
├── argocd-apps/
│   ├── k8sgpt-app.yaml
│   └── monitoring-app.yaml
├── alertmanager/
│   └── webhook-config.yaml  # Phase 3 — triggers K8sGPT on alert
├── docs/
│   └── architecture.png
└── README.md


--------------------------------------------------------------------------------------

**Networking**
- VPC (1, custom CIDR e.g. `10.0.0.0/16`)
- Public subnets × 2 (different AZs — `us-east-1a`, `us-east-1b`)
- Internet Gateway
- Route tables (public + private) + associations

**EKS**
- EKS Cluster (control plane)
- EKS Managed Node Group (`t3.large` × 2)
- EKS Addons — `coredns`, `kube-proxy`, `vpc-cni`, `aws-ebs-csi-driver`
- OIDC Identity Provider (for IRSA — required for K8sGPT + ArgoCD image updater)

**IAM**
- EKS Cluster IAM Role + policy attachments
- EKS Node Group IAM Role + policy attachments (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`)
- K8sGPT IRSA Role (federated trust to OIDC + `bedrock:InvokeModel` permission)
- ArgoCD IRSA Role (optional but good — `secretsmanager` or ECR access)

**Security Groups**
- EKS Cluster SG (control plane)
- Node Group SG (workers — allow traffic from control plane)

**Storage**
- S3 bucket — tfstate backend (versioning enabled)
- DynamoDB table — tfstate locking (`LockID` as partition key, `PAY_PER_REQUEST` billing)

**Outputs needed** (for Helm phase later)
- Cluster name
- Cluster endpoint
- OIDC provider ARN
- OIDC provider URL
- K8sGPT IAM role ARN
- Node group IAM role ARN
- VPC ID

---

**What you do NOT need in Terraform:**
- ALB (ArgoCD will use `LoadBalancer` service type or port-forward for personal project)
- ACM cert (no custom domain needed)
- Route53
- ECR (not needed for this project)
- Bedrock model enablement (console click, can't be done via TF)

---------------------------------------------------------------------------------


# Add repos
helm repo add jetstack https://charts.jetstack.io
helm repo add k8sgpt https://charts.k8sgpt.ai
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

Then install cert-manager:
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.1 \
  --set crds.enabled=true

kubectl get pods -n cert-manager 

helm install k8sgpt-operator k8sgpt/k8sgpt-operator \
  --namespace k8sgpt-operator-system \
  --create-namespace

kubectl get pods -n k8sgpt-operator-system

--
kubectl apply -f helm/k8sgpt/k8sgpt-bedrock.yaml

#  no IRSA annotation. Run the fix:
# Annotate the service account with your Bedrock IAM role
kubectl annotate sa k8sgpt-operator-controller-manager \
  -n k8sgpt-operator-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::660235343049:role/eks-aiops-cluster-k8sgpt-bedrock-role \
  --overwrite

# Restart operator to pick up the annotation
kubectl rollout restart deployment k8sgpt-operator-controller-manager \
  -n k8sgpt-operator-system

# Wait for it to come back up
kubectl rollout status deployment k8sgpt-operator-controller-manager \
  -n k8sgpt-operator-system

  --
  kubectl annotate sa k8sgpt-k8sgpt-operator-system \
  -n k8sgpt-operator-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::660235343049:role/eks-aiops-cluster-k8sgpt-bedrock-role \
  --overwrite
--

kubectl describe pod -l app=k8sgpt-bedrock -n k8sgpt-operator-system | grep -A5 "Events:"