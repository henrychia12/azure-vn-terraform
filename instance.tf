resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "testVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform test"
    }
}

resource "azurerm_subnet" "myterraformsubnet"{
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location
