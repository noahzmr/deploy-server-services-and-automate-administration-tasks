# Define a Kubernetes service for MariaDB in the "learnitnow" namespace.
resource "kubernetes_service" "mariadb" {
  depends_on = [azurerm_kubernetes_cluster.noerkel_k8s]
  metadata {
    name      = "mariadb-service"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    selector = {
      app = "mariadb"
    }

    port {
      port        = var.db_port
      target_port = var.db_port
    }
    type = "ClusterIP"
  }
}

# Define a Kubernetes secret for MariaDB initialization in the "learnitnow" namespace.
resource "kubernetes_secret" "mariadb_init" {
  metadata {
    name      = "mariadb-init"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }
  data = {
    "init.sql" : file(var.script_path)
  }
}

# Define a Kubernetes deployment for MariaDB in the "learnitnow" namespace.
resource "kubernetes_deployment" "mariadb" {
  depends_on = [azurerm_kubernetes_cluster.noerkel_k8s]
  metadata {
    name      = "mariadb-deployment"
    namespace = kubernetes_namespace.learnitow.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mariadb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mariadb"
        }
      }

      spec {
        container {
          name  = "mariadb"
          image = "mariadb:latest"

          volume_mount {
            name       = "sql-script"
            sub_path   = "init.sql"
            mount_path = "/docker-entrypoint-initdb.d/init.sql"
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.db_passwort
          }
        }
        volume {
          name = "sql-script"
          secret {
            secret_name = kubernetes_secret.mariadb_init.metadata[0].name
          }
        }
      }
    }
  }
}
