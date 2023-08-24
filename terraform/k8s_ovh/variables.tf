variable "ovh_application_key" {
    type        = string
    description = "this is the ovh application key required by the ovh provider."
}
variable "ovh_application_secret" {
    type        = string
    description = "this is the ovh application secret required by the ovh provider."
}
variable "ovh_consumer_key" {
    type        = string
    description = "this is the ovh consumer key required by the ovh provider."
}
variable "kubernetes_cluster_name" {
    type = string
    default = "lukas_test_cluster"
}
variable "kubernetes_vlan_id" {
    type = string
    default = "1337"
}
variable "os_region_name" {
    type = string
    default = "GRA7"
}
variable "network_region_name" {
    type = string
    default = "GRA11"
}
variable "kubernetes_flavor_name" {
    type = string
    default = "d2-4"
}
variable "network" {
    type = string
    default = "public"
}
variable "kubernetes_nodepool_name" {
    type = string
    default = "testing"
}
variable "kubernetes_private_subnet_start_ip" {
    type = string
    default = "172.16.200.2"
}
variable "kubernetes_private_subnet_end_ip" {
    type = string
    default = "172.16.200.250"
}
variable "kubernetes_private_subnet_network" {
    type = string
    default = "172.16.200.0/24"
}
variable "kubernetes_version" {
    type = string
    default = "1.22"
}
variable "kubernetes_nodepool_desired_nodes" {
    type = string
    default = "1"
}
variable "kubernetes_nodepool_max_nodes" {
    type = string
    default = "5"
}
variable "kubernetes_nodepool_min_nodes" {
    type = string
    default = "1"
}
variable "project" {
    type = string
    default = "d2ef0005942e4fafb37a769f17fabdb4"
}