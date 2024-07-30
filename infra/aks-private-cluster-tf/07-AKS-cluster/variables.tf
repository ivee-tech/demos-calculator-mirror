#############
# VARIABLES #
#############

variable "prefix" {
    default = "akscs"
}

variable "state_sa_name" {
    default = "stgauaeadevtfstate"
}

variable "container_name" {
    default = "akscs"
}

variable "access_key" {}

variable "private_dns_zone_name" {
default =  "privatelink.australiaeast.azmk8s.io"
}

variable "private_dns_zone_name_resource_group_name" {
    default = "escs-hub-HUB"
}

variable "network_plugin" {
default = "azure"
}

variable "pod_cidr" {
    default = null
}

variable "aksops_object_id" {
    default = "71faa1f5-3673-4036-ac0f-c43c35473fc0"
}

variable "appdev_object_id" {
    default = "8d292bf8-0028-4127-b63b-79c7958fc912"
}

