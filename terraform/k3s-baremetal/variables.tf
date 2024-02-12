variable "user_name" {
  description = "SSH Username for VMs"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "kubernetes_version" {
  description = "Version of K3s to install"
  default     = "v1.21.5+k3s1"
}

variable "external_ip" {
  description = "external ip to connect to"
  default     = "1.2.3.4"
}

variable "port" {
  description = "external ip to connect to"
  default     = "60022"
}