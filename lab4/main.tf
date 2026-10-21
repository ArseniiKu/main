terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
}

variable "managed_nodes" {
  description = "Список узлов, которые мы берем под управление"
  type        = list(string)
  default     = ["node1", "node2"]
}

resource "lxd_instance" "existing_nodes" {
  for_each = toset(var.managed_nodes)

  name     = each.key
  image    = "ubuntu:24.04"
  profiles = ["default"]

  limits = {
    cpu    = "2"
    memory = "2GiB"
  }

  config = {
    "user.managed_by" = "terraform"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "10GB"
    }
  }

  lifecycle {
    ignore_changes = [
      image,
    ]
  }
}
