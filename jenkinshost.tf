# Create public IPs
resource "azurerm_public_ip" "jenkinshostpip" {
    name                         = "jenkinsHostPublicIP"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "jenkinshost-${formatdate("DDMMYYhhmmss", timestamp())}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "jenkinshostnsg" {
    name                = "jenkinsHostNetworkSecurityGroup"
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
        name                       = "Jenkins"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "jenkinshostnic" {
    name                      = "jenkinsHostNIC"
    location                  = "${azurerm_resource_group.main.location}"
    resource_group_name       = "${azurerm_resource_group.main.name}"
    network_security_group_id = "${azurerm_network_security_group.jenkinshostnsg.id}"

    ip_configuration {
        name                          = "jenkinsHostNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.jenkinshostpip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.main.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.main.name}"
    location                    = "${azurerm_resource_group.main.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "jenkinshostvm" {
    name                  = "jenkinsHostVM"
    location              = "${azurerm_resource_group.main.location}"
    resource_group_name   = "${azurerm_resource_group.main.name}"
    network_interface_ids = ["${azurerm_network_interface.jenkinshostnic.id}"]
    vm_size               = "Standard_B1MS"

    storage_os_disk {
        name              = "jenkinsHostOsDisk"
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
        admin_username = "jenkinshost"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/jenkinshost/.ssh/authorized_keys"
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
        command = "ssh-keygen -t rsa -f ~/.ssh/jenkins_host_key -q -P ''"
        }

    provisioner "remote-exec" {
        inline = [
                  "git clone https://github.com/henrychia12/jenkinsTask.git", 
                  "cd ~/jenkinsTask/scripts", 
                  "./install.sh"
                  ]
        connection {
	    type = "ssh"
	    user = "jenkinshost"
	    private_key = file("~/.ssh/id_rsa")
	    host = "${azurerm_public_ip.jenkinshostpip.fqdn}"
        }
    }

    provisioner " local-exec" {
        command = "scp ~/.ssh/jenkins_host_* jenkinshost@${azurerm_public_ip.jenkinshostpip.fqdn}:~/.ssh"
        }    
}
