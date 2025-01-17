resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

# resource "azurerm_resource_group" "rg" {
#   name     = random_pet.rg-name.id
#   location = var.resource_group_location
# }

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.resource_group_location
}

resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}

locals {
  front_door_profile_name      = "fd-auea-dev-x01"
  front_door_endpoint_name     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
  front_door_origin_group_name = "fd-auea-dev-x01-origin-group"
  front_door_origin_name       = "fd-auea-dev-x01-origin"
  front_door_route_name        = "fd-auea-dev-x01-rt"
}

resource "azurerm_cdn_frontdoor_profile" "front_door_x01" {
  name                = local.front_door_profile_name
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = var.front_door_sku_name
}

resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint_x01" {
  name                     = local.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door_x01.id
}

resource "azurerm_cdn_frontdoor_origin_group" "fd_origin_group_x01" {
  name                     = local.front_door_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door_x01.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# resource "azurerm_cdn_frontdoor_origin" "my_app_service_origin" {
#   name                          = local.front_door_origin_name
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id

#   enabled                        = true
#   host_name                      = azurerm_windows_web_app.app.default_hostname
#   http_port                      = 80
#   https_port                     = 443
#   origin_host_header             = azurerm_windows_web_app.app.default_hostname
#   priority                       = 1
#   weight                         = 1000
#   certificate_name_check_enabled = true
# }

# resource "azurerm_cdn_frontdoor_route" "my_route" {
#   name                          = local.front_door_route_name
#   cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint_x01.id
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id
#   cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.my_app_service_origin.id]

#   supported_protocols    = ["Http", "Https"]
#   patterns_to_match      = ["/*"]
#   forwarding_protocol    = "HttpsOnly"
#   link_to_default_domain = true
#   https_redirect_enabled = true
# }