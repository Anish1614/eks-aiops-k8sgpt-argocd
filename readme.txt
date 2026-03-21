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