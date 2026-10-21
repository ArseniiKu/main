output "managed_nodes_info" {
  description = "IP-адреса и статус управляемых узлов"
  value = {
    for name, node in lxd_instance.existing_nodes :
    name => {
      ip     = node.ipv4_address
      status = node.status
    }
  }
}
