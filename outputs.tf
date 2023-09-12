output "resource_group_name" {
  value = azurerm_resource_group.noerkelit_school.name
}

output "kubernetes_config" {
  value = {
    filename = "kubeconfig_noerkelit.yaml"
    content  = azurerm_kubernetes_cluster.noerkel_k8s.kube_config_raw
  }
  sensitive = true
}
