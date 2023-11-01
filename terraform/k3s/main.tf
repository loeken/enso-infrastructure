resource "null_resource" "ssh_key_gen" {
  connection {
    type        = "ssh"
    host        = var.external_ip
    user        = var.user_name
    private_key = file("~/.ssh/id_ed25519")
    port        = var.port
  }

    provisioner "remote-exec" {
    inline = [
        "mkdir -p /home/${var.user_name}/.ssh",
        "if [ ! -f /home/${var.user_name}/.ssh/id_ed25519 ]; then ssh-keygen -t ed25519 -f /home/${var.user_name}/.ssh/id_ed25519 -N ''; fi"
    ]
    }
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P ${var.port} ${var.user_name}@${var.external_ip}:/home/${var.user_name}/.ssh/id_ed25519.pub /tmp/${replace(var.external_ip, ".", "_")}_id_ed25519.pub"
  }
}

data "local_file" "proxmox_pub_key" {
  filename = "/tmp/${replace(var.external_ip, ".", "_")}_id_ed25519.pub"
  depends_on = [null_resource.ssh_key_gen]
}

resource "proxmox_vm_qemu" "k3s-vm" {
  count = var.vm_count
  agent = 1
  onboot = true
  name = "${var.proxmox_vm_name}-${format("%02d", count.index+1)}"
  target_node = var.node_names[count.index % length(var.node_names)]
  clone = "template-${var.node_names[count.index % length(var.node_names)]}"
  full_clone = true
  os_type = "cloud-init"
  sockets = 1
  cores = var.vm_core_count
  memory = var.vm_memory_mb
  scsihw = "virtio-scsi-pci"
  ipconfig0 = "ip=dhcp"
  sshkeys = "${file("~/.ssh/id_ed25519.pub")}\n${data.local_file.proxmox_pub_key.content}"
  ciuser = var.user_name
  qemu_os = "l26"
  vcpus = var.vm_core_count
  disk {
    type    = "virtio"
    storage = "local"
    size = "${var.vm_disk_size_gb}G"
  }
  lifecycle {
    ignore_changes = [
        network
    ]
  }
  network {
    model = "virtio"
    bridge = "vmbr0"
    macaddr = "${var.macaddr_first_five}:${format("%02x", count.index+1)}"
  }
  depends_on = [
    null_resource.ssh_key_gen
  ]
}

resource "null_resource" "update" {
  count = var.vm_count
  depends_on = [proxmox_vm_qemu.k3s-vm]
  connection {
      type        = "ssh"
      host        = proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address
      user        = var.user_name
      private_key = file("~/.ssh/id_ed25519")

      bastion_host = var.external_ip
      bastion_port = var.port
      bastion_user = var.user_name
      bastion_private_key = file("~/.ssh/id_ed25519")
  }
  
  provisioner "remote-exec" {
    inline = [
        "sudo apt update",
        "sudo apt upgrade -y",
        "timeout 10s sh -c 'until ping6 -c 1 ipv6.google.com; do sleep 1; done'",
    ]
  }
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${var.port} ${var.user_name}@${var.external_ip} 'curl -s ifconfig.co -6' > /tmp/ipv6_address_${var.proxmox_vm_name}_${count.index}"
  }
}
data "local_file" "ipv6_address" {
  depends_on = [null_resource.update]
  filename = "/tmp/ipv6_address_${var.proxmox_vm_name}_${count.index}"
}
resource "null_resource" "k3sup_installation" {
  connection {
    type        = "ssh"
    host        = var.external_ip
    user        = var.user_name
    private_key = file("~/.ssh/id_ed25519")
    port        = var.port
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sLS https://get.k3sup.dev | sh",
      "sudo install k3sup /usr/local/bin/"
    ]
  }
  depends_on = [
    null_resource.update
  ]
}
resource "null_resource" "k3s-installation" {
  count      = 1
  depends_on = [null_resource.update, null_resource.k3sup_installation]

  connection {
    type        = "ssh"
    host        = var.external_ip
    user        = var.user_name
    private_key = file("~/.ssh/id_ed25519")
    port        = var.port
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        ipv6_address=${data.local_file.ipv6_address.content}
        if [ -z "$ipv6" ]; then
          echo "No IPv6 address found."
          extra_args="--disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address} --cluster-init"
        else
          echo "IPv6 address found: $ipv6"
          extra_args="--cluster-cidr=10.42.0.0/16,$ipv6/56 --service-cidr=10.43.0.0/16,$ipv6/112 --disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address} --cluster-init"
        fi
        k3sup install --host ${proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address} --ssh-key /home/${var.user_name}/.ssh/id_ed25519 --user ${var.user_name} --cluster --k3s-version ${var.kubernetes_version} --k3s-extra-args "$extra_args" && echo 'waiting 1 minute for the metrics api to be up' && sleep 60
      EOT
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
}

resource "null_resource" "k3s-join-master" {
  count = var.vm_count > 1 ? var.vm_count - 1 : 0
  depends_on = [null_resource.k3s-installation]

  connection {
      type        = "ssh"
      host        = var.external_ip
      user        = var.user_name
      private_key = file("~/.ssh/id_ed25519")
      port        = var.port
  }

  provisioner "remote-exec" {
      inline = [
          <<-EOT
            ipv6_address=${data.local_file.ipv6_address.content}
            if [[ -z "$ipv6" ]]; then
              extra_args="--disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address}"
            else
              extra_args="--cluster-cidr=10.42.0.0/16,$ipv6/56 --service-cidr=10.43.0.0/16,$ipv6/112 --disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address}"
            fi
            k3sup join --server --host ${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --ssh-key /home/${var.user_name}/.ssh/id_ed25519 --user ${var.user_name} --server-ip ${proxmox_vm_qemu.k3s-vm[0].default_ipv4_address} --k3s-version ${var.kubernetes_version} --k3s-extra-args "$extra_args"
          EOT
      ]
  }
}

resource "null_resource" "k3s-join-worker" {
  count = var.vm_count > 3 ? var.vm_count - 1 : 0
  depends_on = [null_resource.k3s-join-master]

  connection {
      type        = "ssh"
      host        = var.external_ip
      user        = var.user_name
      private_key = file("~/.ssh/id_ed25519")
      port        = var.port
  }

  provisioner "remote-exec" {
      inline = [
          <<-EOT
            ipv6_address=${data.local_file.ipv6_address.content}
            if [[ -z "$ipv6" ]]; then
              extra_args="--disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address}"
            else
              extra_args="--cluster-cidr=10.42.0.0/16,$ipv6/56 --service-cidr=10.43.0.0/16,$ipv6/112 --disable=traefik,servicelb --node-external-ip=${var.external_ip} --advertise-address=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --node-ip=${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address}"
            fi
            k3sup join --host ${proxmox_vm_qemu.k3s-vm[count.index+1].default_ipv4_address} --ssh-key /home/${var.user_name}/.ssh/id_ed25519 --user ${var.user_name} --server-ip ${proxmox_vm_qemu.k3s-vm[0].default_ipv4_address} --k3s-version ${var.kubernetes_version} --k3s-extra-args "$extra_args"
          EOT
      ]
  }
}

resource "null_resource" "upload_ips" {
    count = var.vm_count
    depends_on = [null_resource.k3s-join-master]
    connection {
        type     = "ssh"
        host     = proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address
        user     = var.user_name
        private_key = file("~/.ssh/id_ed25519")
        bastion_host = var.external_ip
        bastion_port = var.port
        bastion_user = var.user_name
        bastion_private_key = file("~/.ssh/id_ed25519")
    }
    provisioner "file" {
        source     = "update_ips.sh"
        destination = "/tmp/update_ips.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/update_ips.sh",
            "sudo mv /tmp/update_ips.sh /usr/local/bin/",
        ]
    }
}
resource "null_resource" "create_cronjob" {
  count = var.vm_count
  depends_on = [null_resource.upload_ips]
  
  connection {
    type        = "ssh"
    host        = proxmox_vm_qemu.k3s-vm[count.index].default_ipv4_address
    user        = var.user_name
    private_key = file("~/.ssh/id_ed25519")
    bastion_host = var.external_ip
    bastion_port = var.port
    bastion_user = var.user_name
    bastion_private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "remote-exec" {
    inline = [
      "echo '* * * * * root /usr/local/bin/update_ips.sh' | sudo tee /etc/cron.d/update_ips_cron",
      "sudo chmod 0644 /etc/cron.d/update_ips_cron",
      "sudo systemctl restart cron",
    ]
  }
}