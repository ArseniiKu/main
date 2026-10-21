variable "name" {
  description = "Имя контейнера"
  type        = string
}

variable "cpu" {
  description = "Количество ядер CPU"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Лимит оперативной памяти"
  type        = string
  default     = "1GiB"
}

variable "disk_size" {
  description = "Размер корневого диска"
  type        = string
  default     = "10GiB"
}

resource "lxd_instance" "this" {
  name     = var.name
  type     = "container"
  image    = "ubuntu:24.04"
  profiles = ["default"]

  config = {
    "user.managed_by" = "terraform"
  }

  limits = {
    memory = var.memory
    cpu    = tostring(var.cpu)
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = var.disk_size
    }
  }
}

output "container_ip" {
  description = "IP-адрес контейнера"
  value       = lxd_instance.this.ipv4_address
}

output "container_name" {
  value = lxd_instance.this.name
}
