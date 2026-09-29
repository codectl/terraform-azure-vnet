module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "northeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "rg_remote" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  providers = {
    azurerm = azurerm.remote
  }

  groups = {
    demo = {
      name     = "${module.naming.resource_group.name_unique}-remote"
      location = "northeurope"
    }
  }
}


module "vnet_local" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = "${module.naming.virtual_network.name}-hub"
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.0.0.0/16"]
  }
}

module "vnet_remote" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  providers = {
    azurerm = azurerm.remote
  }

  vnet = {
    name                = "${module.naming.virtual_network.name}-spoke"
    location            = module.rg_remote.groups.demo.location
    resource_group_name = module.rg_remote.groups.demo.name
    address_space       = ["10.1.0.0/16"]
  }
}

module "peering" {
  source  = "codectl/vnet/azure//modules/vnet-peering"
  version = "~> 1.0"

  providers = {
    azurerm.remote = azurerm.remote
  }

  vnet_peering = {
    local = {
      peering_name          = "local-to-remote"
      name                  = module.vnet_local.vnet.name
      id                    = module.vnet_local.vnet.id
      resource_group_name   = module.vnet_local.vnet.resource_group_name
      address_space         = module.vnet_local.vnet.address_space
      use_remote_gateways   = false
      allow_gateway_transit = false
    }
    remote = {
      peering_name          = "remote-to-local"
      name                  = module.vnet_remote.vnet.name
      id                    = module.vnet_remote.vnet.id
      resource_group_name   = module.vnet_remote.vnet.resource_group_name
      address_space         = module.vnet_remote.vnet.address_space
      use_remote_gateways   = false
      allow_gateway_transit = false
    }
  }
}
