data "template_file" "init" {
  template = file("${path.module}/scripts/cloud_init.cfg")

  vars = {
    opnsense_config = file("${path.module}/configs/default_opnsense_config.xml")
  }
}
resource "proxmox_vm_qemu" "opnsense" {
  count = var.vm_count
  agent = 1
  onboot = true
  name = "${var.proxmox_vm_name}-${format("%02d", count.index+1)}"
  target_node = var.node_names[count.index % length(var.node_names)]
  clone = "template-opnsense-${var.node_names[count.index % length(var.node_names)]}"
  full_clone = true
  os_type = "cloud-init"
  sockets = 1
  cores = var.vm_core_count
  memory = var.vm_memory_mb
  scsihw = "virtio-scsi-pci"
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=static"
  sshkeys = "${file("~/.ssh/id_ed25519.pub")}\n${data.local_file.proxmox_pub_key.content}"
  ciuser = var.user_name
  qemu_os = "l26"
  vcpus = var.vm_core_count
  cicustom = "user=local:cloudinit ${data.template_file.init.rendered}"
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
  network {
    model = "virtio"
    bridge = "vmbr1"
  }
  depends_on = [
    null_resource.ssh_key_gen
  ]
}