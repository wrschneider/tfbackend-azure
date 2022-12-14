resource "random_id" "this" {
  byte_length = "10"
}

resource "random_string" "this" {
  length  = 10
  special = false
  upper   = false
}

##### Locals
locals {
  # Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only
  storage_account_name = "${var.name_prefix}${random_string.this.result}"
  container_name       = "tfstatecontainer"
}


# Create a storage account only if it has not been passed as variable
resource "azurerm_storage_account" "tfstate" {
  count                           = var.storage_account_name == "" ? 1 : 0
  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

# create a storage container oly if it has not been passed as variable
resource "azurerm_storage_container" "tfstate" {
  count                 = var.container_name == "" ? 1 : 0
  name                  = local.container_name
  storage_account_name  = var.storage_account_name == "" ? azurerm_storage_account.tfstate[0].name : var.storage_account_name
  container_access_type = "private"
}

################# AUTOMATING REMOTE STATE LOCKING
data "template_file" "remote_state" {
  template = file("${path.module}/templates/remote_state.tpl")
  vars = {
    resource_group_name  = var.resource_group_name
    storage_account_name = var.storage_account_name == "" ? azurerm_storage_account.tfstate[0].name : var.storage_account_name
    container_name       = var.container_name == "" ? azurerm_storage_container.tfstate[0].name : var.container_name
    key                  = var.key
  }
}

resource "local_file" "remote_state_locks" {
  content  = data.template_file.remote_state.rendered
  filename = var.backend_output_path
}
