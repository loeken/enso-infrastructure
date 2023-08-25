data "ovh_order_cart" "mycart" {
    ovh_subsidiary = "de"
    description    = "my cloud order cart"
}

data "ovh_order_cart_product_plan" "cloud" {
    cart_id        = data.ovh_order_cart.mycart.id
    price_capacity = "renew"
    product        = "cloud"
    plan_code      = "project.2018"
}

resource "ovh_cloud_project" "cloudproject" {
    ovh_subsidiary = data.ovh_order_cart.mycart.ovh_subsidiary
    description    = "project_" + var.name
    plan {
        duration     = data.ovh_order_cart_product_plan.cloud.selected_price.0.duration
        plan_code    = data.ovh_order_cart_product_plan.cloud.plan_code
        pricing_mode = data.ovh_order_cart_product_plan.cloud.selected_price.0.pricing_mode
    }
}


resource "ovh_cloud_project_network_private" "net" {
    count = var.network == "private" ? 1 : 0
    service_name = cloudproject.project_id
    name       = var.kubernetes_cluster_name
    regions     = [var.os_region_name]
    vlan_id    = var.kubernetes_vlan_id
    depends_on = [
        ovh_cloud_project.cloudproject
    ]
}

resource "ovh_cloud_project_network_private_subnet" "subnet" {
    count = var.network == "private" ? 1 : 0k
    service_name = cloudproject.project_id
    network_id = ovh_cloud_project_network_private.net[0].id
    region     = var.os_region_name
    start      = var.kubernetes_private_subnet_start_ip
    end        = var.kubernetes_private_subnet_end_ip
    network    = var.kubernetes_private_subnet_network
    dhcp       = true
    no_gateway = true
    depends_on = [
        ovh_cloud_project.cloudproject,
        ovh_cloud_project_network_private.net
    ]
}

resource "ovh_cloud_project_kube" "kubernetes_cluster" {
    service_name = cloudproject.project_id
    name         = var.kubernetes_cluster_name
    region     = var.os_region_name
    version      = var.kubernetes_version
    private_network_id = var.network == "private" ? tolist(ovh_cloud_project_network_private.net[0].regions_attributes[*].openstackid)[0] : null
    depends_on = [
        ovh_cloud_project_network_private_subnet.subnet
    ]
}

resource "ovh_cloud_project_kube_nodepool" "main_pool" {
    service_name  = cloudproject.project_id
    kube_id       = ovh_cloud_project_kube.kubernetes_cluster.id
    name          = var.kubernetes_nodepool_name
    flavor_name   = var.kubernetes_flavor_name
    desired_nodes = var.kubernetes_nodepool_desired_nodes
    max_nodes     = var.kubernetes_nodepool_max_nodes
    min_nodes     = var.kubernetes_nodepool_min_nodes
    autoscale =  true
}

resource "local_file" "kubeconfig" {
    content     = ovh_cloud_project_kube.kubernetes_cluster.kubeconfig
    filename = "${path.module}/kubeconfig"
    lifecycle {
        ignore_changes = [
            filename,
            content
        ]
    }
}
