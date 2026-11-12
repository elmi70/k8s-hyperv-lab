packer {
  required_plugins {
    hyperv  = { source = "github.com/hashicorp/hyperv", version = ">= 1.1.4, < 2.0.0" }
    vagrant = { source = "github.com/hashicorp/vagrant", version = ">= 1.1.5, < 2.0.0" }
  }
}
variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/26.04.1/ubuntu-26.04.1-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:cc8a95cde20f6ced61a322420de00f10cc3c90ced545daa46cb9c1a117f1d927"
}

variable "hyperv_switch_name" {
  type    = string
  default = "Default Switch"
}

locals {
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz net.ifnames=0 autoinstall<enter><wait5s>",
    "initrd /casper/initrd<enter><wait5s>",
    "boot<enter><wait5s>"
  ]
}
source "hyperv-iso" "ubuntu2604" {
  iso_url               = var.iso_url
  iso_checksum          = var.iso_checksum
  switch_name           = var.hyperv_switch_name
  cd_label              = "cidata"
  cd_files              = ["autoinstall/user-data", "autoinstall/meta-data"]
  boot_command          = local.boot_command
  boot_wait             = "5s"
  boot_order            = ["SCSI:0:0"]
  first_boot_device     = "DVD"
  generation            = 2
  enable_secure_boot    = true
  secure_boot_template  = "MicrosoftUEFICertificateAuthority"
  enable_dynamic_memory = false
  cpus                  = 2
  memory                = 4096
  disk_size             = 32768
  headless              = true
  communicator          = "ssh"
  ssh_username          = "vagrant"
  ssh_password          = "vagrant"
  ssh_timeout           = "60m"
  shutdown_command      = "echo 'vagrant' | sudo -S poweroff"
}
build {
  sources = ["source.hyperv-iso.ubuntu2604"]
  provisioner "shell" {
    scripts = ["scripts/setup.sh"]
  }
  post-processor "vagrant" {
    output            = "output/ubuntu-26.04.1-hyperv.box"
    compression_level = 9
  }
}
