resource "null_resource" "k3s_installation" {
  connection {
    type        = "ssh"
    user        = var.user_name
    private_key = file(var.ssh_private_key_path)
    host        = var.external_ip
    port        = var.port
  }

  provisioner "remote-exec" {
    inline = [
      "k3sup install --ip ${var.external_ip} --user ${var.user_name} --ssh-key ${var.ssh_private_key_path} --k3s-version ${var.kubernetes_version} --cluster",
    ]
  }
}

output "k3s_cluster_info" {
  value = "K3s cluster installed on node with IP: ${var.external_ip}"
}
