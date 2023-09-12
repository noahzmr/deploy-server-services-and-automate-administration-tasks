resource "kubernetes_service" "learnitnow_service" {
  metadata {
    name      = "learnitnow-service"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    selector = {
      app = "learnitnow"
    }

    port {
      port        = var.learnitnow_port
      target_port = var.learnitnow_port
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_secret" "learnitnow_certificate" {
  metadata {
    name      = "my-learnitnow-certs"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }
  data = {
    "cert.pem" : file(var.cert)
    "cert.key" : file(var.key)
  }
}

resource "kubernetes_deployment" "learnitnow_deployment_v2" {
  metadata {
    name      = "my-learnitnow-deployment"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "learnitnow"
      }
    }

    template {
      metadata {
        labels = {
          app = "learnitnow"
        }
      }

      spec {
        container {
          name  = "learnitnow-container"
          image = var.learnitnow_docker_image

          port {
            container_port = var.learnitnow_port
          }

          volume_mount {
            name       = "certificate"
            sub_path   = "cert.pem"
            mount_path = "/noerkelit/learnitnow/cert/cert.cer"
          }

          volume_mount {
            name       = "certificate"
            sub_path   = "cert.key"
            mount_path = "/noerkelit/learnitnow/cert/key.key"
          }

          env {
            name  = "DB_HOST"
            value = var.db_ipv4
          }

          env {
            name  = "DB_PORT"
            value = var.db_port
          }
          env {
            name  = "DB_USER"
            value = var.db_user
          }
          env {
            name  = "DB_PASSWORD"
            value = var.db_passwort
          }
          env {
            name  = "DB_DATABASE"
            value = var.db_name
          }
        }

        volume {
          name = "certificate"
          secret {
            secret_name = kubernetes_secret.learnitnow_certificate.metadata[0].name
          }
        }

      }
    }
  }
}

