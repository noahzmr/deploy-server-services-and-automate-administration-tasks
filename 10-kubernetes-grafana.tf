resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      port        = 80
      target_port = 3000
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          image = "grafana/grafana:latest"
          name  = "grafana"

          env {
            name  = "GF_SECURITY_ADMIN_USER"
            value = "adm.nzeumer"
          }
          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "grafana.adm.nzeumer"
          }

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}
