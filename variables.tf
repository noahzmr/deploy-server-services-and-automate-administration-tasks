# Azure
variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
  sensitive   = true
}

variable "client_id" {
  type        = string
  description = "Azure Client"
}

variable "client_secret" {
  type        = string
  description = "Azure Password for the Client"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant for the Client"
}

variable "azure_location" {
  type        = string
  description = "Azure Server Location"
}

# Network
variable "address_space_main" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.address_space_main))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

variable "address_space_vpc_clients" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.address_space_vpc_clients))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

variable "kubernetes_cidr" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.kubernetes_cidr))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

variable "address_space_hosted_services" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.address_space_hosted_services))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

variable "address_space_vpn_clients" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.address_space_vpn_clients))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

# General User
variable "username" {
  type        = string
  description = "User Name Shorrt for user three"
}


variable "nze_ssh_pub" {
  description = "NZeumer Pub SSH Key"
  type        = string
  sensitive   = true
}

variable "nze_password" {
  description = "NZeumer password default"
  type        = string
  sensitive   = true
}


# LearnITnow
variable "learnitnow_docker_image" {
  type        = string
  description = "LearnITnow Docker Image Url"
}

variable "learnitnow_ipv4" {
  type        = string
  description = "IPv4 Address for the NodeJS LearnITnow Container"
}

variable "learnitnow_port" {
  type        = number
  description = "Port for the NodeJS LearnITnow Container"
}

# Chat NoerkelIT
variable "chat_docker_image" {
  type        = string
  description = "NoerkelIT Chat Docker Image Url"
}

variable "chat_ipv4" {
  type        = string
  description = "IPv4 Address for the Chat"
}

variable "chat_port" {
  type        = number
  description = "Port for the Chat"
  default     = 10000
}
variable "chat_db" {
  type        = string
  description = "Name of the Chat Database"
  default     = "noerkelit_chat"
}

variable "chat_mail" {
  type        = string
  description = "Name of the Chat Mailer"
}

variable "chat_mail_password" {
  type        = string
  description = "Passowrd of the Chat Mailer"
  sensitive   = true
}

variable "chat_mail_port" {
  type        = number
  description = "Port of the Chat Mailer"
  default     = 993
}

variable "chat_mail_tls" {
  type        = bool
  description = "Want TLS for the Chat Mailer"
  default     = false
}

variable "chat_mail_secure" {
  type        = bool
  description = "Want Mailer Secure"
  default     = true
}

variable "chat_mail_service" {
  type        = string
  description = "Mail Provider"
  default     = "imap.ionos.de"
}

variable "chat_mail_showname" {
  type        = string
  description = "Display name"
  default     = "<Noerkel IT>"
}

variable "chat_minio_endpoint" {
  type        = string
  description = "Display name"
}

variable "chat_minio_ssl" {
  type        = bool
  description = "Want SSL cumminication"
  default     = false
}


# Minio
variable "minio_port" {
  type        = number
  description = "Port for Minio"
  default     = 9001
}

variable "minio_port_endpoint" {
  type        = number
  description = "Port for Minio Endpoints"
  default     = 9000
}

variable "minio_user" {
  type        = string
  description = "User for Minio"
}

variable "minio_user_password" {
  type        = string
  description = "Password for the user of Minio"
  sensitive   = true
}
variable "minio_ipv4" {
  type        = string
  description = "IPv4 Address for the Minio"
}

# MariaDb
variable "db_passwort" {
  type        = string
  description = "Password for the MariaDB"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Name for the MariaDB Database"
}

variable "db_ipv4" {
  type        = string
  description = "IPv4 Address for the MariaDB"
}

variable "db_user" {
  type        = string
  description = "User for the MariaDB"
}

variable "db_port" {
  type        = number
  description = "Port for the MariaDB"
}

variable "script_path" {
  type        = string
  description = "Init SQL Script Path"
}


# OpenVpn
variable "openvpn_ipv4" {
  type        = string
  description = "IPv4 Address for the OpenVpn"
}

# Nextcloud
variable "nextcloud_ipv4" {
  type        = string
  description = "IPv4 Address for the NextCloud"
}

# Grafana
variable "grafana_ipv4" {
  type        = string
  description = "IPv4 Address for the Grafana"
}

# Kubernetes
variable "dns_kubernetes_ipv4" {
  type        = string
  description = "IPv4 Address for the Kubernetes DNS"
}

variable "service_cidr" {
  type        = string
  description = "IP Address with Prefix"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/\\d{1,2}$", var.service_cidr))
    error_message = "The IP address with prefix is not valid! It should look like 0.0.0.0/0"
  }
}

variable "kubeconfig_path" {
  type        = string
  description = "kubeconfig_path"
}

# SSL 
variable "cert" {
  type        = string
  description = "Cert.cer for SSL"
  sensitive   = true
}

variable "key" {
  type        = string
  description = "key.key for SSL"
  sensitive   = true
}

# Windows AD

variable "domain_name" {
  type    = string
  default = "noerkelit.online"
}

variable "dc_name" {
  type    = string
  default = "dc-01"
}


variable "domain_netbios_name" {
  type    = string
  default = "noerkelit"
}

variable "domain_mode" {
  type    = string
  default = "WinThreshold"
}

variable "database_path" {
  type    = string
  default = "C:/Windows/NTDS"
}

variable "sysvol_path" {
  type    = string
  default = "C:/Windows/SYSVOL"
}

variable "log_path" {
  type    = string
  default = "C:/Windows/NTDS"
}

variable "safe_mode_administrator_password" {
  type    = string
}

variable "dc_ipv4" {
  type        = string
  description = "IPv4 Address for the Domain Controller"
}
