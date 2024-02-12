resource "null_resource" "k3s_installation" {
  count = length(var.vm_ips)

  connection {
    type        = "ssh"
    user        = var.user_name
    private_key = file(var.ssh_private_key_path)
    host        = element(var.vm_ips, count.index)
  }

  provisioner "remote-exec" {
    inline = [
      count.index < 3 ? "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.kubernetes_version} sh -s - --write-kubeconfig-mode 644" :
        "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.kubernetes_version} K3S_URL=https://${element(var.vm_ips, 0)}:6443 K3S_TOKEN=$(ssh ${var.user_name}@${element(var.vm_ips, 0)} 'sudo cat /var/lib/rancher/k3s/server/node-token') sh -s -",
    ]
  }

  # Optional: Add a delay for non-master nodes to ensure masters are fully set up
  provisioner "local-exec" {
    command = "sleep 30"
    when    = count.index >= 3 ? "create" : "destroy"
  }
}

output "k3s_master_node" {
  value = element(var.vm_ips, 0)
}

output "k3s_worker_nodes" {
  value = slice(var.vm_ips, 1, length(var.vm_ips))
}