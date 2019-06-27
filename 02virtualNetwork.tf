resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "testVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform test"
    }
}

