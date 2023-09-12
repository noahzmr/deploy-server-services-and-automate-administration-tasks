provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "kubernetes_namespace" "learnitow" {
  depends_on = [azurerm_kubernetes_cluster.noerkel_k8s]
  metadata {
    name = "learnitnow"
  }
}

