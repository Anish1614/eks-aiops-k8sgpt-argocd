variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "monitoring-platform"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
