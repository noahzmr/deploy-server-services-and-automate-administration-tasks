##########################
# Start of one VPC Block #
# ########################
resource "azurerm_network_interface" "vpc_nze_nic" {
  name                = "vpc_nze_nic"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name

  ip_configuration {
    name                          = "vpc_nze_nic_config"
    subnet_id                     = azurerm_subnet.vpc_clients.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vpc_nze_vm" {
  # Optimize the name for the user
  name                  = "nzeumer-vm-01"
  location              = azurerm_resource_group.noerkelit_school.location
  resource_group_name   = azurerm_resource_group.noerkelit_school.name
  network_interface_ids = [azurerm_network_interface.vpc_nze_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osNzeVpcUbu"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name = "nzeumer-vm-01"
    # Optimize Username
    admin_username = var.username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.username}/.ssh/authorized_keys"
      # SSH Pub key from the user
      key_data = var.nze_ssh_pub
    }
  }
}

resource "azurerm_virtual_machine_extension" "setup_vpc_nze" {
  name                 = "customscript"
  virtual_machine_id   = azurerm_virtual_machine.vpc_nze_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
     {
         "script": ""
     }
 SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
     {
         "script": "${base64encode(file("${path.module}/script/client_netdata.sh"))}"
     }
 PROTECTED_SETTINGS
}

resource "azurerm_network_interface_security_group_association" "vpc_nze_nic_association" {
  network_interface_id      = azurerm_network_interface.vpc_nze_nic.id
  network_security_group_id = azurerm_network_security_group.vpc_client_nsg.id
}

##########################
# Start of one VPC Block #
# ########################
