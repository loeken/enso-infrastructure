# Define providers and set versions
terraform {
required_version    = ">= 1.4.6" # Takes into account Terraform versions from 0.14.0
    required_providers {
        openstack = {
            source  = "terraform-provider-openstack/openstack"
            version = "~> 1.52.1"
        }

        ovh = {
            source  = "ovh/ovh"
            version = ">= 0.32.0"
        }
    }
}
# Configure the OpenStack provider hosted by OVHcloud
provider "openstack" {
    auth_url    = "https://auth.cloud.ovh.net/v3/" # Authentication URL
    domain_name = "default" # Domain name - Always at 'default' for OVHcloud
    alias       = "ovh" # An alias
}

# Configure the OVHcloud Provider
provider "ovh" {
    endpoint           = "ovh-eu"
    application_key    = var.ovh_application_key
    application_secret = var.ovh_application_secret
    consumer_key       = var.ovh_consumer_key
}
