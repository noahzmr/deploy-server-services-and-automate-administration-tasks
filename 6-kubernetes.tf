resource "azurerm_kubernetes_cluster" "noerkel_k8s" {
  location            = azurerm_resource_group.noerkelit_school.location
  name                = "noerkel-k8s"
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  dns_prefix          = "noerkel-k8s"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = 2
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = var.nze_ssh_pub
    }
  }
  network_profile {
    network_plugin = "azure"
    dns_service_ip = var.dns_kubernetes_ipv4
    service_cidr   = var.service_cidr
  }
}

resource "null_resource" "generate_kubeconfig" {
  triggers = {
    kubeconfig = azurerm_kubernetes_cluster.noerkel_k8s.kube_config_raw
  }

  provisioner "local-exec" {
    command = "echo '${azurerm_kubernetes_cluster.noerkel_k8s.kube_config_raw}' > ${var.kubeconfig_path}"
  }

  depends_on = [azurerm_kubernetes_cluster.noerkel_k8s]
}
