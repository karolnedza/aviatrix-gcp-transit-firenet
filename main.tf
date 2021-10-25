module "gcp_ha_transit_1" {
  source             = "./terraform-aviatrix-gcp-transit-firenet"
  account            = "gcp-account"
  name = "gcp-transit"

  transit_cidr  = "10.0.0.0/24" # /24 for insance mode!
  firewall_cidr = "10.0.1.0/26"

  bootstrap_bucket_name = "av-pan-bootstrap"
  
  ha_gw = true
  insane_mode = true


  region    = "europe-west1"

  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall BYOL"
  firewall_image_version = "9.1.3"
}
