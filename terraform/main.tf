terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.0"
        }
    }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "iac-example-build" {
    name     = "iac-example-build"
    location = "West Europe"
}

resource "azurerm_virtual_network" "iac-example-build" {
    name                = "iac-example-build-vnet"
    resource_group_name = azurerm_resource_group.iac-example-build.name
    location            = azurerm_resource_group.iac-example-build.location
    address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "iac-example-build" {
    name                 = "iac-example-build-subnet"
    resource_group_name  = azurerm_resource_group.iac-example-build.name
    virtual_network_name = azurerm_virtual_network.iac-example-build.name
    address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "iac-example-build" {
    name                = "iac-example-build-pip"
    resource_group_name = azurerm_resource_group.iac-example-build.name
    location            = azurerm_resource_group.iac-example-build.location
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_network_security_group" "iac-example-build" {
    name                = "iac-example-build-nsg"
    resource_group_name = azurerm_resource_group.iac-example-build.name
    location            = azurerm_resource_group.iac-example-build.location

    security_rule {
        name                        = "iac-example-build-nsg-rule"
        priority                    = 100
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "22"
        source_address_prefix       = "*"
        destination_address_prefix  = "*"
    }
}

resource "azurerm_network_interface_security_group_association" "iac-example-build" {
    network_interface_id      = azurerm_network_interface.iac-example-build.id
    network_security_group_id = azurerm_network_security_group.iac-example-build.id
}

resource "azurerm_network_interface" "iac-example-build" {
    name                = "iac-example-build-nic"
    location            = azurerm_resource_group.iac-example-build.location
    resource_group_name = azurerm_resource_group.iac-example-build.name

    ip_configuration {
        name                          = "iac-example-build-nic-ip"
        subnet_id                     = azurerm_subnet.iac-example-build.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.iac-example-build.id
    }
}

resource "azurerm_linux_virtual_machine" "iac-example-build" {
    name                  = "iac-example-build-vm"
    resource_group_name   = azurerm_resource_group.iac-example-build.name
    location              = azurerm_resource_group.iac-example-build.location
    size                  = "Standard_B2ls_v2"
    admin_username        = "azureuser"
    network_interface_ids = [azurerm_network_interface.iac-example-build.id]

    admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    custom_data = base64encode(file("cloud-init.yaml"))

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
    }
}