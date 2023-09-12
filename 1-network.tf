# Define an Azure Virtual Network with the name "noerkelit-school-vnet."
resource "azurerm_virtual_network" "main" {
  name                = "noerkelit-school-vnet"
  address_space       = [var.address_space_main] # The main address space of the VNet
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name
}

# Define a subnet for hosted services within the VNet defined above.
resource "azurerm_subnet" "services_network" {
  name                 = "services_network"
  resource_group_name  = azurerm_resource_group.noerkelit_school.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.address_space_hosted_services] # Address space for hosted services
}

# Define a subnet for VPN clients within the VNet defined above.
resource "azurerm_subnet" "vpn_clients" {
  name                 = "VPN-Clients"
  resource_group_name  = azurerm_resource_group.noerkelit_school.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.address_space_vpn_clients] # Address space for VPN clients
}

# Define a subnet for VPC clients within the VNet defined above.
resource "azurerm_subnet" "vpc_clients" {
  name                 = "VPC-Clients"
  resource_group_name  = azurerm_resource_group.noerkelit_school.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.address_space_vpc_clients] # Address space for VPC clients
}

# Define a subnet for Kubernetes clusters within the VNet defined above.
resource "azurerm_subnet" "kubernetes_network" {
  name                 = "Kubernetes-Network"
  resource_group_name  = azurerm_resource_group.noerkelit_school.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.kubernetes_cidr] # Address space for the Kubernetes network
}

# Define a public IP address for the gateway service.
resource "azurerm_public_ip" "gateway" {
  name                = "noerkelit.school-public-ip"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  allocation_method   = "Dynamic" # Dynamic allocation of the IP address
}
