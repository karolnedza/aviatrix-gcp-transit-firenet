module "gcp_ha_transit_1" {
  source             = "./terraform-aviatrix-gcp-transit-firenet"
  transit_firenet  = true
  account            = "gcp-account"
  name = "gcp-transit"

  transit_cidr              = "10.0.0.0/28" # /26 for insance mode!
  ha_transit_cidr           = "10.0.0.64/28"
  insane_mode = true

  lan_subnet_cidr  = "10.0.0.128/28"
  ha_lan_subnet_cidr = "10.0.1.64/28"

  egress_subnet_cidr = "10.0.0.160/28"
  ha_egress_subnet_cidr = "10.0.0.192/28"

  mgmt_subnet_cidr = "10.0.0.224/28"
  ha_mgmt_subnet_cidr = "10.0.1.0/28"

  prefix = false
  suffix = false

  region    = "europe-west1"
  ha_region = "europe-west1"


  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall BYOL"
  firewall_image_version = "9.1.3"
}
