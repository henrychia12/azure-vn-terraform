resource "azurerm_resource_group" "main" {
    name     = "myResourceGroup"
    location = "uksouth"

    tags = {
        environment = "Terraform Demo"
    }
}

