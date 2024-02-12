variable "vm_ips" {
  description = "List of VM IPs"
  type        = list(string)
}

variable "user_name" {
  description = "SSH Username for VMs"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of K3s to install"
  default     = "v1.21.5+k3s1"
}