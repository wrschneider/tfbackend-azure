# tfbackend-azure


A Terraform module to bootstrap the creation of Azure resources required to use Azure Blob Storage as the backend for Terraform
state.

This module would typically run once per Azure subscription.  You would run this module with 
Terraform local state, to generate the backend configuration required to store state for other Terraform infrastructure. Effectively,
this is using Terraform as a domain-specific language (DSL) for creating Azure resources.

## Need for Configuring remote state backend

Terraform state is used to reconcile deployed resources with Terraform configurations. State allows Terraform to know what Azure resources to add, update, or delete.

By default, Terraform state is stored locally, which isn't ideal for the following reasons:

    * Local state doesn't work well in a team or collaborative environment.
    * Terraform state can include sensitive information.
    * Storing state locally increases the chance of inadvertent deletion.

Refer: https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage

## Basic Usage

First, make sure you can authenticate to your Azure Subscription with `az login`. You'll need Contributor or equivalent access.

Then create a repo to hold your Terraform code. In that repo put a `main.tf` file.

It will have two blocks of content.

The first is the meta info to hook your terraform to your subscription and the second implements this module. 

##### Terraform & Provider Block:

```hcl
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "00000000-0000-0000-0000-000000000000"
}
```

##### Module Configuration Block (examples):

(`vars` should be defined before `terraform plan/apply`)

```hcl
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

module "tfbackend-azure" {
  source   = "git::https://github.com/Optum/tfbackend-azure.git?ref=master"

  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location
}
```

```hcl
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

# You can pass storage account
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

module "tfbackend-azure" {
  source   = "git::https://github.com/Optum/tfbackend-azure.git?ref=master"

  resource_group_name  = azurerm_resource_group.tfstate.name
  storage_account_name = azurerm_storage_account.tfstate.name
}
```

This creates a `backend.tf` file in the specified `backend_output_path` (default: project directory). Apply the configured backend by running `terraform init` again

### Refer /examples directory for a complete example to setup a azure backend for the terraform.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| azurerm | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 2.0.0 |
| null | n/a |
| random | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| backend\_output\_path | The default file to output backend configuration to | `string` | `"./backend.tf"` | no |
| container\_name | The Name of the Storage Container within the Storage Account. | `string` | `""` | no |
| key | The name of the Blob used to retrieve/store Terraform's State file inside the Storage Container. | `string` | `"global/terrform.tfstate"` | no |
| name\_prefix | The prefix for all created resources | `string` | `"tfstate"` | no |
| resource\_group\_name | The Name of the Resource Group in which the Storage Account exists. | `any` | n/a | yes |
| storage\_account\_name | The name of the storage account | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| key | The name of the Blob created to retrieve/store Terraform's State file inside the Storage Container |
| storage\_account\_name | Name of created storage account |
| storage\_container | Name of created storage container |
| backend_file_content | Content of the backend file|

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
