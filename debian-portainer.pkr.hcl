variable "iso_file" {
  type    = string
  default = "isos:iso/debian-11.6.0-amd64-netinst.iso"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "40G"
}

variable "disk_storage_pool" {
  type    = string
  default = "vm-pool"
}

variable "disk_storage_pool_type" {
  type    = string
  default = "zfs"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "network_vlan" {
  type    = string
  default = ""
}

variable "proxmox_api_token_id" {
  type      = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}


source "proxmox-iso" "debian11-portainer" {

  proxmox_url = "${var.proxmox_api_url}"
  username = "${var.proxmox_api_token_id}"
  token = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true


  template_description = "Debian Portainer template. Built on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  node                 = var.proxmox_node
  vm_id = 4002
  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "virtio"
    vlan_tag = var.network_vlan
  }

  disks {
    disk_size         = var.disk_size
    format            = var.disk_format
    io_thread         = true
    storage_pool      = var.disk_storage_pool
    storage_pool_type = var.disk_storage_pool_type
    type              = "scsi"
  }

  scsi_controller = "virtio-scsi-single"

  iso_file       = var.iso_file
  http_directory = "./"
  boot_wait      = "10s"
  boot_command   = ["<esc><wait>auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"]
  unmount_iso    = true

  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  vm_name  = "debian11-portainer"
  #cpu_type = "EPYC"
  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  sockets  = "1"

  ssh_password = "packer"
  ssh_username = "root"
}

build {
  sources = ["source.proxmox-iso.debian11-portainer"]

   provisioner "ansible" {
      playbook_file = "ansible/playbook.yml"
      user = "root" 
      ansible_ssh_extra_args = [
                "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -o IdentitiesOnly=yes"
                ] 
      extra_arguments = [ "--scp-extra-args", "'-O'" ]
      
  }
}
