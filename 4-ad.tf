locals {
  cmd00      = "Set-TimeZone -Id 'W. Europe Standard Time'"
  cmd01      = "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools"
  cmd02      = "Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools"
  cmd03      = "Import-Module ADDSDeployment, DnsServer"
  cmd04      = "Install-ADDSForest -DomainName ${var.domain_name} -DomainNetbiosName ${var.domain_netbios_name} -DomainMode ${var.domain_mode} -ForestMode ${var.domain_mode} -DatabasePath ${var.database_path} -SysvolPath ${var.sysvol_path} -LogPath ${var.log_path} -NoRebootOnCompletion:$false -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.safe_mode_administrator_password}' -AsPlainText -Force)"
  powershell = "${local.cmd00};${local.cmd01}; ${local.cmd02}; ${local.cmd03}; ${local.cmd04}"
}

resource "azurerm_network_interface" "winosnic" {
  name                = "${var.dc_name}-nic"
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  location            = azurerm_resource_group.noerkelit_school.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.services_network.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dc_ipv4
  }

}

resource "azurerm_windows_virtual_machine" "dc_vm" {
  name                = var.dc_name
  resource_group_name = azurerm_resource_group.noerkelit_school.name
  location            = azurerm_resource_group.noerkelit_school.location
  size                = "Standard_DS1_v2"
  admin_username      = var.username
  admin_password      = var.nze_password
  network_interface_ids = [
    azurerm_network_interface.winosnic.id,
  ]

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface_security_group_association" "securitygroup" {
  network_interface_id      = azurerm_network_interface.winosnic.id
  network_security_group_id = azurerm_network_security_group.hosted_services_nw_nsg.id
}

resource "azurerm_virtual_machine_extension" "software" {
  depends_on = [azurerm_windows_virtual_machine.dc_vm]

  name                       = "setup-dc"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
     {
         "commandToExecute": ""
     }
 SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
     {
         "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -Command \"${local.powershell}\""
     }
 PROTECTED_SETTINGS
}
