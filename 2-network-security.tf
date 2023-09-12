resource "azurerm_network_security_group" "open_vpn_ssh" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name

  security_rule {
    name                       = "OpenVPN"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "19443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH_Backup"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_ICMP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-services-to-vpn"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_hosted_services
    destination_address_prefix = var.address_space_vpn_clients
  }
  security_rule {
    name                       = "allow-rdp-from-services"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "hosted_services_nw_nsg" {
  name                = "hostedServicesNwNsg"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name

  security_rule {
    name                       = "OpenVPN"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "19443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH_Backup"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_ICMP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "vpn_client_nsg" {
  name                = "vpn-client-nsg"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  security_rule {
    name                       = "allow-vpn-to-services"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpn_clients
    destination_address_prefix = var.address_space_hosted_services
  }

  security_rule {
    name                       = "allow-vpn-to-kubernetes"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpn_clients
    destination_address_prefix = var.kubernetes_cidr
  }
  security_rule {
    name                       = "allow-vpn-to-vpc"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpn_clients
    destination_address_prefix = var.address_space_vpc_clients
  }

  security_rule {
    name                       = "allow-dhcp-to-vpn-clients"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "67-68"
    source_address_prefix      = var.address_space_vpn_clients
    destination_address_prefix = var.address_space_vpn_clients
  }
}

resource "azurerm_network_security_group" "vpc_client_nsg" {
  name                = "vpc-client-nsg"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  security_rule {
    name                       = "allow-vpc-to-services"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpc_clients
    destination_address_prefix = var.address_space_hosted_services
  }

  security_rule {
    name                       = "allow-vpc-to-kubernetes"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpc_clients
    destination_address_prefix = var.kubernetes_cidr
  }
  security_rule {
    name                       = "allow-vpc-to-vpn"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.address_space_vpc_clients
    destination_address_prefix = var.address_space_vpn_clients
  }
}

resource "azurerm_network_security_group" "kubernetes_nsg" {
  name                = "k8s-nsg"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  security_rule {
    name                       = "allow-k8s-to-services"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.kubernetes_cidr
    destination_address_prefix = var.address_space_hosted_services
  }

  security_rule {
    name                       = "allow-k8s-to-vpn"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.kubernetes_cidr
    destination_address_prefix = var.address_space_vpn_clients
  }
  security_rule {
    name                       = "allow-k8s-to-vpc"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.kubernetes_cidr
    destination_address_prefix = var.address_space_vpc_clients
  }

  security_rule {
    name                       = "Nginx"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Nginx-secure"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "learn-app"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vpn_client_nsg_association" {
  subnet_id                 = azurerm_subnet.vpn_clients.id
  network_security_group_id = azurerm_network_security_group.vpn_client_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "kubernetes_nsg_association" {
  subnet_id                 = azurerm_subnet.kubernetes_network.id
  network_security_group_id = azurerm_network_security_group.kubernetes_nsg.id
}
