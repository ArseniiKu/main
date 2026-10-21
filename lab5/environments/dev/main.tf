terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
}

module "web_server" {
  source = "../../modules/lxd_instance"
  name      = "tf-web-01"
  cpu       = 2
  memory    = "2GiB"
  disk_size = "15GiB"
}

module "db_server" {
  source = "../../modules/lxd_instance"
  name      = "tf-db-01"
  cpu       = 4
  memory    = "4GiB"
  disk_size = "30GiB"
}

output "web_server_ip" {
  value = module.web_server.container_ip
}

output "web_server_name" {
  value = module.web_server.container_name
}
