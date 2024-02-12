resource "null_resource" "k3s_installation" {
  # Using local-exec to run k3sup install locally within the Docker container
  provisioner "local-exec" {
    command = "k3sup install --ip ${var.external_ip} --user ${var.user_name} --ssh-key ${var.ssh_private_key_path} --k3s-version ${var.k3s_version} --cluster"
  }
}

output "k3s_cluster_info" {
  value = "K3s cluster installed on node with IP: ${var.external_ip}"
}
