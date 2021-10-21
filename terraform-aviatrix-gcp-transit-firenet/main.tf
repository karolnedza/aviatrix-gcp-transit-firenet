# Transit VPC
# Information on GCP Regions and Zones https://cloud.google.com/compute/docs/regions-zones
# GCP zones b,c are almost universally available that's why we chose them


data "aviatrix_account" "account_id" {
  account_name = var.account
}


resource "aviatrix_vpc" "default" {
  cloud_type           = 4
  account_name         = var.account
  name                 = local.name
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = local.name
    cidr   = var.transit_cidr
    region = var.region
  }

  dynamic "subnets" {
    for_each = length(var.ha_region) > 0 ? ["dummy"] : []
    content {
      name   = "${local.name}-ha"
      cidr   = var.ha_transit_cidr
      region = var.ha_region
    }
  }
}



resource "aviatrix_vpc" "mgmt_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-mgmt"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-mgmt"
    cidr   = var.mgmt_subnet_cidr
    region = var.region
  }

  dynamic "subnets" {
    for_each = length(var.ha_region) > 0 ? ["dummy"] : []
    content {
      name   = "${local.name}-mgmt-ha"
      cidr   = var.ha_mgmt_subnet_cidr
      region = var.ha_region
    }
  }
}



resource "aviatrix_vpc" "lan_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-lan"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false

  subnets {
    name   = "${local.name}-lan"
    cidr   = var.lan_subnet_cidr
    region = var.region
  }

  dynamic "subnets" {
    for_each = length(var.ha_region) > 0 ? ["dummy"] : []
    content {
      name   = "${local.name}-lan-ha"
      cidr   = var.ha_lan_subnet_cidr
      region = var.ha_region
    }
  }
}

resource "aviatrix_vpc" "egress_vpc" {
  cloud_type           = 4
  account_name         = var.account
  name                 = "${local.name}-egress"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  subnets {
    name   = "${local.name}-egress"
    cidr   = var.egress_subnet_cidr
    region = var.region
  }

  dynamic "subnets" {
    for_each = length(var.ha_region) > 0 ? ["dummy"] : []
    content {
      name   = "${local.name}-egress-ha"
      cidr   = var.ha_egress_subnet_cidr
      region = var.ha_region
    }
  }
}


resource "aviatrix_transit_gateway" "default" {
  gw_name                          = local.name
  vpc_id                           = aviatrix_vpc.default.name
  cloud_type                       = 4
  vpc_reg                          = local.region1
  enable_active_mesh               = var.active_mesh
  gw_size                          = var.instance_size
  account_name                     = var.account
  subnet                           = local.transit_subnet
  insane_mode                      = var.insane_mode
  ha_subnet                        = var.ha_gw ? local.ha_transit_subnet : null
  ha_gw_size                       = var.ha_gw ? var.instance_size : null
  ha_zone                          = var.ha_gw ? local.region2 : null
  connected_transit                = var.connected_transit
  bgp_manual_spoke_advertise_cidrs = var.bgp_manual_spoke_advertise_cidrs
  enable_learned_cidrs_approval    = var.learned_cidr_approval
  enable_transit_firenet            = var.transit_firenet
  enable_segmentation              = var.enable_segmentation
  single_az_ha                     = var.single_az_ha
  single_ip_snat                   = var.single_ip_snat
  lan_vpc_id                       = aviatrix_vpc.lan_vpc.name
  lan_private_subnet               = local.lan_subnet
  enable_advertise_transit_cidr    = var.enable_advertise_transit_cidr
  bgp_polling_time                 = var.bgp_polling_time
  bgp_ecmp                         = var.bgp_ecmp
}



resource "aviatrix_firewall_instance" "firewall_instance" {
  count                  = var.ha_gw ? 0 : 1
  firewall_name          = "${local.name}-fw"
  firewall_size          = var.fw_instance_size
  vpc_id                 = "${local.name}~-~${data.aviatrix_account.account_id.gcloud_project_id}"
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = "${local.egress_subnet}~~${var.region}~~${local.name}-egress"
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = "${local.mgmt_subnet}~~${var.region}~~${local.name}-mgmt"
  management_vpc_id =    aviatrix_vpc.mgmt_vpc.vpc_id
  egress_vpc_id =  aviatrix_vpc.egress_vpc.vpc_id
  zone                   = var.ha_gw ? local.region1 : null
}



resource "aviatrix_firewall_instance" "firewall_instance_1" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw1"
  firewall_size          = var.fw_instance_size
  vpc_id                 = "${local.name}~-~${data.aviatrix_account.account_id.gcloud_project_id}"
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = "${local.egress_subnet}~~${var.region}~~${local.name}-egress"
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = "${local.mgmt_subnet}~~${var.region}~~${local.name}-mgmt"
  management_vpc_id =    aviatrix_vpc.mgmt_vpc.vpc_id
  egress_vpc_id =  aviatrix_vpc.egress_vpc.vpc_id
  zone                   = var.ha_gw ? local.region1 : null
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw2"
  firewall_size          = var.fw_instance_size
  vpc_id                 = "${local.name}~-~${data.aviatrix_account.account_id.gcloud_project_id}"
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = "${local.ha_egress_subnet}~~${var.region}~~${local.name}-egress-ha"
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  management_subnet      = "${local.ha_mgmt_subnet}~~${var.region}~~${local.name}-mgmt-ha"
  management_vpc_id =  aviatrix_vpc.mgmt_vpc.vpc_id
  egress_vpc_id = aviatrix_vpc.egress_vpc.vpc_id
  zone                   = var.ha_gw ? local.region2 : null
}



resource "aviatrix_firenet" "firenet" {
  vpc_id                               = format("%s~-~%s", aviatrix_transit_gateway.default.vpc_id, data.aviatrix_account.account_id.gcloud_project_id)
  inspection_enabled                   = var.inspection_enabled
  egress_enabled                       = false
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.firenet_instance, aviatrix_firewall_instance_association.firenet_instance1, aviatrix_firewall_instance_association.firenet_instance2]
}


resource "aviatrix_firewall_instance_association" "firenet_instance" {
  count                = var.ha_gw ? 0 : 1
  vpc_id               = aviatrix_vpc.default.vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance[0].instance_id
  firewall_name        = aviatrix_firewall_instance.firewall_instance[0].firewall_name
  lan_interface        = aviatrix_firewall_instance.firewall_instance[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance[0].egress_interface
  attached             = true
}

resource "aviatrix_firewall_instance_association" "firenet_instance1" {
  count                = var.ha_gw ? 1 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_1[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_1[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_1[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_1[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_1[0].egress_interface
  attached             = true
}

resource "aviatrix_firewall_instance_association" "firenet_instance2" {
  count                = var.ha_gw ? 1 : 0
  vpc_id               = aviatrix_firewall_instance.firewall_instance_2[0].vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
  instance_id          = aviatrix_firewall_instance.firewall_instance_2[0].instance_id
  lan_interface        = aviatrix_firewall_instance.firewall_instance_2[0].lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance_2[0].management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance_2[0].egress_interface
  attached             = true
}
