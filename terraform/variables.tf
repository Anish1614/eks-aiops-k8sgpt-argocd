variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "eks-aiops-cluster"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
