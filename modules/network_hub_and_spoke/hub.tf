#-------------------------------------------------------------------------------
# Call the hub module
#-------------------------------------------------------------------------------

module "hub" {
  source = "./hub"

  providers = {
    aws     = aws.hub
    aws.hub = aws.hub
  }

  namespace = var.namespace
  env       = var.env
  project   = var.project
  is_prod   = var.is_prod

  hub_vpc_cidr = var.hub_vpc_cidr

  availability_zones = var.availability_zones

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  spoke_vpc_cidrs = toset([for k, v in var.spoke_vpcs : v.cidr])
}
