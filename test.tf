# Create a resource group
resource "azurerm_resource_group" "UST-RG" {
  name     = "UST-resource-group"
  location = "eastus"
}

# Create a virtual network
resource "azurerm_virtual_network" "UST-VN" {
  name                = "UST-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.UST-RG.location
  resource_group_name = azurerm_resource_group.UST-RG.name
}

# Create a public subnet
resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.UST-RG.name
  virtual_network_name = azurerm_virtual_network.UST-VN.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create 4 private subnets
resource "azurerm_subnet" "private-1" {
  name                 = "private-subnet-1"
  resource_group_name  = azurerm_resource_group.UST-RG.name
  virtual_network_name = azurerm_virtual_network.UST-VN.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "private-2" {
  name                 = "private-subnet-2"
  resource_group_name  = azurerm_resource_group.UST-RG.name
  virtual_network_name = azurerm_virtual_network.UST-VN.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "private-3" {
  name                 = "private-subnet-3"
  resource_group_name  = azurerm_resource_group.UST-RG.name
  virtual_network_name = azurerm_virtual_network.UST-VN.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "private-4" {
  name                 = "private-subnet-4"
  resource_group_name  = azurerm_resource_group.UST-RG.name
  virtual_network_name = azurerm_virtual_network.UST-VN.name
  address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_public_ip" "PIP" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.UST-RG.name
  location            = azurerm_resource_group.UST-RG.location
  allocation_method   = "Dynamic"
}

# Create a network security group
resource "azurerm_network_security_group" "UST-SG" {
  name                = "UST-nsg"
  location            = azurerm_resource_group.UST-RG.location
  resource_group_name = azurerm_resource_group.UST-RG.name
}

# Create a network security group rule
resource "azurerm_network_security_rule" "UST-SG-RULE" {
  name                        = "UST-nsg-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.UST-RG.name
  network_security_group_name = azurerm_network_security_group.UST-SG.name
}

# Create a network security group rule to allow SSH traffic
resource "azurerm_network_security_rule" "UST-SG-SSH" {
  name                        = "UST-nsg-ssh"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.UST-RG.name
  network_security_group_name = azurerm_network_security_group.UST-SG.name
}

# Create a virtual network interface with the security group
resource "azurerm_network_interface" "UST-VI" {
  name                = "UST-nic"
  location            = azurerm_resource_group.UST-RG.location
  resource_group_name = azurerm_resource_group.UST-RG.name

  ip_configuration {
    name                          = "UST-ip-config"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PIP.id
  }
}

resource "azurerm_network_interface_security_group_association" "UST-SG-ASSOCIATION" {
  network_interface_id      = azurerm_network_interface.UST-VI.id
  network_security_group_id = azurerm_network_security_group.UST-SG.id
}
resource "azurerm_virtual_machine" "UST-VM" {
  name                  = "UST-vm"
  location              = azurerm_resource_group.UST-RG.location
  resource_group_name   = azurerm_resource_group.UST-RG.name
  network_interface_ids = [azurerm_network_interface.UST-VI.id]
  vm_size = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "UST-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "UST-vm"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd1234"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdXAV7Dhxh6xFP2+Hxg9wIOaozJaQlKDrvaNw4C1sBGgSPXHeqRyRQXT1X+ThLvOpxle5+8mN43m84eaIcjaAIfNHDjLtWM0YBJE39+82ef65wtiYEMCy1RDR6AgCnU8ul2GyyzVJOd5JxLtfLdV93Y420NoSc6DfMyrMouk3bIpKWeyUkWYvADqETY3+BvkW21e8YxHBv5GNKpdCd3//srmyb+apQKZp/s4E8ug6jpPjZQKPDCrDv2SI0NkEZ5Kpp+7kANxTaeCrgr0uFpJP8wvXAcFPCrk6sPg3CUCSAyl6Vr48uy3IC3c6/47I0VQQ0Q6igkcsIEuYE/Oob5L5MLZqvOkdPZIUD2KQZ/vjwXns7oXHatGeu9AFFeKAGyPuqYduQrv6+8dSigICLKaxHZglTgc2QCWnVsoieBY7BPU4IwKwY1K4wx/eiomNUXHkLBvDopgNTV38oLrMy0jH4zw1niWLu9BS+0opbyP+quwP+0DFGA/f3OUR9NDxpsg8= root@DESKTOP-DAMATKJ"
    }
  }
}