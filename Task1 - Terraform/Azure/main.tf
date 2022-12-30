# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#vars
variable env_prefix {}
variable avn_cidr_block{}
variable subnet_cidr_block{}
variable profilepass{}


# Create a resource group
resource "azurerm_resource_group" "myapp-rg" {
  name     = "${var.env_prefix}-rg"
  location = "West Europe"
}

# Create a Virtual network
resource "azurerm_virtual_network" "mypp-vnetwork" {
  name                = "${var.env_prefix}-vnetwork"
  resource_group_name = azurerm_resource_group.myapp-rg.name
  location            = azurerm_resource_group.myapp-rg.location
  address_space       = [var.avn_cidr_block]
}

# Create subnet
resource "azurerm_subnet" "myapp-subnet-1" {
  name                 = "${var.env_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.myapp-rg.name
  virtual_network_name = azurerm_virtual_network.mypp-vnetwork.name
  address_prefixes     = [var.subnet_cidr_block]
}

resource "azurerm_network_interface" "myapp-ninterface" {
  name                = "${var.env_prefix}-nic"
  location            = azurerm_resource_group.myapp-rg.location
  resource_group_name = azurerm_resource_group.myapp-rg.name

  ip_configuration {
    name                          = "${var.env_prefix}-ip"
    subnet_id                     = azurerm_subnet.myapp-subnet-1.id
    private_ip_address_allocation = "Dynamic"

  }
}

#virtual machine 
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.env_prefix}-vm"
  location              = azurerm_resource_group.myapp-rg.location
  resource_group_name   = azurerm_resource_group.myapp-rg.name
  network_interface_ids = [azurerm_network_interface.myapp-ninterface.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "var.profilepass"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "${var.env_prefix}-vm"
  }
}


resource "azurerm_network_security_group" "my-sg" {
  name                = "${var.env_prefix}-my-sg"
  resource_group_name = azurerm_resource_group.myapp-rg.name
  location            = azurerm_resource_group.myapp-rg.location

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "${var.env_prefix}-sg"
  }
}