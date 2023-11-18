terraform {
    required_providers {
        proxmox = {
            source = "loeken/proxmox"
            version = "2.9.16"
        }
    }
}
provider "proxmox" {
    pm_api_url = "https://localhost:${var.tunnel_port}/api2/json" 
    pm_password = var.root_password
    pm_user = "root@pam"
    pm_tls_insecure = "true"
} 
