terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "alt_qemu" {
  name = "altlinux"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-altlinux"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "altlinux-qcow2" {
  name   = "altlinux-qcow2"
  pool   = libvirt_pool.alt_qemu.name
  format = "qcow2"
  size   = 16 * 1024 * 1024 * 1024
}

# Create the machine
resource "libvirt_domain" "domain-altlinux" {
  name   = "altlinux-terraform"
  memory = "512"
  vcpu   = 2


  # network_interface { network_name = "default" }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.altlinux-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
