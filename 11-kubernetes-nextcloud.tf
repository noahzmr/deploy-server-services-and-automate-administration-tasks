resource "kubernetes_service" "nextcloud_service" {
  metadata {
    name      = "nextcloud-deployment"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    selector = {
      app = "nextcloud"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "nextcloud_deployment" {
  metadata {
    name      = "nextcloud-deployment"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nextcloud"
      }
    }

    template {
      metadata {
        labels = {
          app = "nextcloud"
        }
      }

      spec {
        container {
          name  = "nextcloud"
          image = "nextcloud:latest"
          port {
            container_port = 80
          }

          volume_mount {
            name       = "nextcloud-data"
            mount_path = "/var/www/html/data"
          }

          env {
            name  = "MYSQL_HOST"
            value = var.db_ipv4
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_USER"
            value = "nextcloud"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = var.db_passwort
          }

        }

        volume {
          name = "nextcloud-data"

          persistent_volume_claim {
            claim_name = "nextcloud-data-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nextcloud_data" {
  metadata {
    name      = "nextcloud-data-pvc"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}
