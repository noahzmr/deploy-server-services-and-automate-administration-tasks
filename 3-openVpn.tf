resource "azurerm_network_interface" "open_vpn_nic" {
  name                = "open_vpn_nic"
  location            = azurerm_resource_group.noerkelit_school.location
  resource_group_name = azurerm_resource_group.noerkelit_school.name

  ip_configuration {
    name                          = "open_vpn_nic_config"
    subnet_id                     = azurerm_subnet.services_network.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.openvpn_ipv4
    public_ip_address_id          = azurerm_public_ip.gateway.id
  }
}

resource "azurerm_virtual_machine" "open_vpn_vm" {
  name                  = "open-vpn-01"
  location              = azurerm_resource_group.noerkelit_school.location
  resource_group_name   = azurerm_resource_group.noerkelit_school.name
  network_interface_ids = [azurerm_network_interface.open_vpn_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osOpenVpnUbu"
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
    computer_name  = "open-vpn-01"
    admin_username = var.username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/admnzeumer/.ssh/authorized_keys"
      key_data = var.nze_ssh_pub
    }
  }
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "customscript"
  virtual_machine_id   = azurerm_virtual_machine.open_vpn_vm.id
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
         "script": "${base64encode(file("${path.module}/script/setup_openvpn.sh"))}"
     }
 PROTECTED_SETTINGS
}

resource "azurerm_network_interface_security_group_association" "open_vpn_ssh" {
  network_interface_id      = azurerm_network_interface.open_vpn_nic.id
  network_security_group_id = azurerm_network_security_group.open_vpn_ssh.id
}
