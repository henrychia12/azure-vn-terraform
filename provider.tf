provider "azurerm" {
    version = "=1.30.1"
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "testResourceGroup"
    location = "uksouth"
    
    tags = {
        environment = "Terraform Demo"
    }
}
