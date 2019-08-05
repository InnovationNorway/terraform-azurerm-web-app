# terraform-azurerm-web-app

## Create a Web App in Azure

This terraform module deploys a Web App on dedicated app service plan, with autoscaling, in Azure. 

The following resources will be created by the module:

- App service plan (S1)
- Web app
- Auto scale settings for app service plan.

## Usage

```hcl

resource "azurerm_resource_group" "image_resizer" {
  name     = "image-resizer-func-rg"
  location = "westeurope"
}

module "Web_app" {
  source                    = "innovationnorway/web-app/azurerm"
  version                   = "0.1.0-pre"
  web_app_name              = "image-resizer-web"
  resource_group_name       = "${azurerm_resource_group.image_resizer.name}"
  location                  = "${azurerm_resource_group.image_resizer.location}"
  environment               = "lab"
  release                   = "release 2018-07-21.001"
  restrict_ip               = "1.2.3.4"
  restrict_subnet_mask      = "255.255.255.0"
  
  app_settings {
  }

  tags {
      a       = "b",
      project = "image-resizing"
  }
}

```

## Inputs

### resource_group_name

The resource group where the resources should be created.

### location

The azure datacenter location where the resources should be created. Defaults to "westeurope"

### web_app_name

The name for the Web app. Without environment naming.

### min_tls_version

Minimum version of TLS the web app should support.

### restrict_ip

The ipv4 address you want to allow accessing the web app

### restrict_subnet_mask

The subnet mask for the ipv4 address you want to allow accessing the web app, defaults to 0.0.0.0 (every ip allowed)

### ftps_state

Which form for ftp the web app file system should support. If not strictly nesasery to use it, leave it disabled, and onlyftps if needed.

### app_settings

Application settings to insert on creating the Web app. Following updates will be ignored, and has to be set manually. Updates done on application deploy or in portal will not affect terraform state file.

### tags

A map of tags to add to all resources. Release and Environment will be auto tagged. 

### environment

The environment where the infrastructure is deployed.

### release

The release the deploy is based on

## Outputs

### identity_principal_id

The MSI identities set on the web app. Returns a list of identities.

### identity_tenant_id

The MSI identity tenant id set on the web app.

### webapp_name

The name of the created web app.

### webapp_serviceplan_name

The name of the created web app service plan.

### webapp_serviceplan_id

The id of the created web app service plan.

### hostname

The Hostname associated with the Web App - such as mysite.azurewebsites.net.
