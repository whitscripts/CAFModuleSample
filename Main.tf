terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.2"
      configuration_aliases = [
        azurerm.connectivity,
        azurerm.management,
      ]
    }
  }
}

provider "azurerm" {
  subscription_id = "<paste your default sudbscription ID here - usually management sub>"
  features {}
}

# Declare an aliased provider block using your preferred configuration.
# This will be used for the deployment of all "Connectivity resources" to the specified `subscription_id`.
provider "azurerm" {
  alias           = "connectivity"
  subscription_id = "<paste connectivity sudbscription ID here>"
  features {}
}

# Declare a standard provider block using your preferred configuration.
# This will be used for the deployment of all "Management resources" to the specified `subscription_id`.
provider "azurerm" {
  alias           = "management"
  subscription_id = "<paste management sudbscription ID here>"
  features {}
} 

provider "azurerm" {
  alias           = "identity"
  subscription_id = "<paste identity sudbscription ID here>"
  features {}
} 

# Get the current client configuration from the AzureRM provider.
# This is used to populate the root_parent_id variable with the
# current Tenant ID used as the ID for the "Tenant Root Group"
# management group.

# data "azurerm_client_config" "core" {}


# Obtain client configuration from the un-aliased provider
data "azurerm_client_config" "core" {
  provider = azurerm
}

# Obtain client configuration from the "management" provider
data "azurerm_client_config" "management" {
  provider = azurerm.management
}

# Obtain client configuration from the "connectivity" provider
data "azurerm_client_config" "connectivity" {
  provider = azurerm.connectivity
}

# Obtain client configuration from the "connectivity" provider
data "azurerm_client_config" "identity" {
  provider = azurerm.identity
}

# Use variables to customize the deployment

variable "root_id" {
  type    = string
  default = "contoso"
}

variable "root_name" {
  type    = string
  default = "Contoso Labs"
}

# Declare the Azure landing zones Terraform module
# and provide a base configuration.

module "enterprise_scale" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "2.3.1"      #defines the CAF Module version you want to use - Suggest specifying a version here to avoid unintended or untested CAF Module updates - have a testing cycle for new module versions

  providers = {
    azurerm              = azurerm
    azurerm.management   = azurerm.management #azurerm.management   = azurerm
    azurerm.connectivity = azurerm.connectivity #azurerm.connectivity = azurerm
    #azurerm.identity     = azurerm.identity
    
  }

  root_parent_id = "<paste your AAD Tenant ID here>" #data.azurerm_client_config.core.tenant_id
  root_id        = "contoso"
  root_name      = "Contoso Labs"

  default_location = "westus3"

  deploy_management_resources = true
  subscription_id_management  = data.azurerm_client_config.management.subscription_id

  deploy_identity_resources = true
  subscription_id_identity  = data.azurerm_client_config.identity.subscription_id

  deploy_connectivity_resources = true
  subscription_id_connectivity  = data.azurerm_client_config.connectivity.subscription_id

 # Configure custom settings for the module to deploy Virtual WAN hub
  # network resources instead of traditional hub network resources.
 configure_connectivity_resources = {
    settings = {
      hub_networks = []
      vwan_hub_networks = [
        {
          enabled = true
          config = {
            address_prefix = "10.100.0.0/22"
            location       = ""
            sku            = ""
            routes         = []
            expressroute_gateway = {
              enabled = false
              config = {
                scale_unit = 1
              }
            }
            vpn_gateway = {
              enabled = false
              config = {
                bgp_settings       = []
                routing_preference = ""
                scale_unit         = 1
              }
            }
            azure_firewall = {
              enabled = false
              config = {
                enable_dns_proxy              = false
                dns_servers                   = []
                sku_tier                      = "Standard"
                base_policy_id                = ""
                private_ip_ranges             = []
                threat_intelligence_mode      = ""
                threat_intelligence_allowlist = []
                availability_zones = {
                  zone_1 = true
                  zone_2 = true
                  zone_3 = true
                }
              }
            }
            spoke_virtual_network_resource_ids = []
            enable_virtual_hub_connections     = false
          }
        },
      ]
      ddos_protection_plan = {
        enabled = false
        config = {
          location = ""
        }
      }
      dns = {
        enabled = true
        config = {
          location = ""
          enable_private_link_by_service = {
            azure_automation_webhook             = true
            azure_automation_dscandhybridworker  = true
            azure_sql_database_sqlserver         = true
            azure_synapse_analytics_sqlserver    = false
            azure_synapse_analytics_sql          = false
            storage_account_blob                 = true
            storage_account_table                = true
            storage_account_queue                = true
            storage_account_file                 = true
            storage_account_web                  = true
            azure_data_lake_file_system_gen2     = false
            azure_cosmos_db_sql                  = true
            azure_cosmos_db_mongodb              = true
            azure_cosmos_db_cassandra            = true
            azure_cosmos_db_gremlin              = false
            azure_cosmos_db_table                = true
            azure_database_for_postgresql_server = true
            azure_database_for_mysql_server      = true
            azure_database_for_mariadb_server    = false
            azure_key_vault                      = true
            azure_kubernetes_service_management  = true
            azure_search_service                 = false
            azure_container_registry             = true
            azure_app_configuration_stores       = true
            azure_backup                         = true
            azure_site_recovery                  = true
            azure_event_hubs_namespace           = true
            azure_service_bus_namespace          = true
            azure_iot_hub                        = false
            azure_relay_namespace                = true
            azure_event_grid_topic               = false
            azure_event_grid_domain              = false
            azure_web_apps_sites                 = true
            azure_machine_learning_workspace     = false
            signalr                              = false
            azure_monitor                        = true
            cognitive_services_account           = false
            azure_file_sync                      = true
            azure_data_factory                   = false
            azure_data_factory_portal            = false
            azure_cache_for_redis                = true
          }
          private_link_locations                                 = []
          public_dns_zones                                       = []
          private_dns_zones                                      = []
          enable_private_dns_zone_virtual_network_link_on_hubs   = true
          enable_private_dns_zone_virtual_network_link_on_spokes = true
        }
      }
    }
    location = null
    tags     = null
    advanced = null
  }




}