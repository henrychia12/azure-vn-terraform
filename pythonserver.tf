resource "azurerm_public_ip" "pythonserverpip" {
    name                         = "pythonServerPublicIP"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "pythonserver-${formatdate("DDMMYYhhmmss", timestamp())}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "pythonservernsg" {
    name                = "pythonServerNetworkSecurityGroup"
    location            = "${azurerm_resource_group.main.location}"
    resource_group_name = "${azurerm_resource_group.main.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "PythonServer"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "pythonservernic" {
    name                      = "pythonServerNIC"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.pythonservernsg.id}"

    ip_configuration {
        name                          = "pythonServerNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.pythonserverpip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "pythonservervm" {
    name                  = "pythonServerVM"
    location              = "${azurerm_resource_group.main.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${azurerm_network_interface.pythonservernic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "pythonServerOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "hostname"
        admin_username = "pythonserver"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/pythonserver/.ssh/authorized_keys"
            key_data = file("~/.ssh/id_rsa.pub")
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }

    provisioner "remote-exec" {
        inline = [
                  "git https://github.com/henrychia12/python-webserver.git" 
                 ]
        connection {
	    type = "ssh"
	    user = "pythonserver"
	    private_key = file("~/.ssh/id_rsa")
	    host = "${azurerm_public_ip.pythonserverpip.fqdn}"
       }
    } 
}
