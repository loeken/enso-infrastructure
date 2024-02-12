resource "null_resource" "k3sup_installation" {
  connection {
    type        = "ssh"
    host        = var.external_ip
    user        = var.user_name
    private_key = file(var.ssh_private_key_path)
    port        = var.port
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sLS https://get.k3sup.dev | sh",
      "sudo install k3sup /usr/local/bin/"
    ]
  }
}
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
  provisioner "local-exec" {
    command = format("scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P %s %s@%s:/home/%s/kubeconfig ./kubeconfig",
      var.port,
      var.user_name,
      var.external_ip,
      var.user_name
    )
  }

  depends_on = [
    null_resource.k3sup_installation
  ]
}

output "k3s_cluster_info" {
  value = "K3s cluster installed on node with IP: ${var.external_ip}"
}
