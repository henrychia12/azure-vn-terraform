resource "azurerm_public_ip" "jenkinsslavepip" {
    name                         = "jenkinsSlavePublicIP"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "jenkinsslave-${formatdate("DDMMYYhhmmss", timestamp())}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "jenkinsslavensg" {
    name                = "jenkinsSlaveNetworkSecurityGroup"
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

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "jenkinsslavenic" {
    name                      = "jenkinsSlaveNIC"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.jenkinsslavensg.id}"

    ip_configuration {
        name                          = "jenkinsSlaveNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.jenkinsslavepip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "jenkinsslavevm" {
    name                  = "jenkinsSlaveVM"
    location              = "${azurerm_resource_group.main.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${azurerm_network_interface.jenkinsslavenic.id}"]
    vm_size               = "Standard_B1MS"

    storage_os_disk {
        name              = "jenkinsSlaveOsDisk"
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
        admin_username = "jenkinsslave"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/jenkinsslave/.ssh/authorized_keys"
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

    provisioner "local-exec" {
        command = "ssh-keygen -t rsa -f ~/.ssh/jenkins_slave_key -q -P ''"
	}

    provisioner "local-exec" {
        command = "yes | cat ~/.ssh/jenkins_host_key.pub | ssh jenkinsslave@${azurerm_public_ip.jenkinsslavepip.fqdn} 'cat >> ~/.ssh/authorized_keys'"
        }

    provisioner "remote-exec" {
        inline = [
                  "git clone https://github.com/henrychia12/python-webserver.git" 
                 ]
        connection {
	    type = "ssh"
	    user = "jenkinsslave"
	    private_key = file("~/.ssh/id_rsa")
	    host = "${azurerm_public_ip.jenkinsslavepip.fqdn}"
       }
    }

    provisioner "local-exec" {
        command = "scp ~/.ssh/jenkins_slave_* jenkinsslave@${azurerm_public_ip.jenkinsslavepip.fqdn}:~/.ssh"
        } 
}
