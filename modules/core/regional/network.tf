#------------------------------------------------------------------------------
# Network resources
# If spend_money = true, it creates an enterprise-ish network
# ...else it creates a more cost-efficient version
#------------------------------------------------------------------------------

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main"

  cidr = var.cidr

  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  public_subnet_tags = {
    Tier                               = "public"
    "kubernetes.io/cluster/impact-eks" = "shared"
    "kubernetes.io/role/elb"           = 1
  }
  private_subnet_tags = {
    Tier                               = "private"
    "kubernetes.io/cluster/impact-eks" = "shared"
    "kubernetes.io/role/internal-elb"  = 1
  }
  database_subnet_tags = {
    Tier = "database"
  }

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = var.spend_money ? true : false
  single_nat_gateway = true

  # VPC endpoint for S3
  enable_s3_endpoint = var.enable_s3_endpoint

  # VPC Endpoint for ECR API
  enable_ecr_api_endpoint = false
  # ecr_api_endpoint_private_dns_enabled = true
  ecr_api_endpoint_security_group_ids = [
    data.aws_security_group.default.id
    //, module.internal_all_security_group.this_security_group_id
  ]

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = [{}]
  default_security_group_egress  = [{}]

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

# module "nat_instance" {
#   source = "../nat_instance"

#   namespace = var.namespace
#   env       = var.env
#   name      = "core"

#   aws_vpc_id        = module.vpc.vpc_id
#   nat_instance_type = "t3.nano"
#   number_of_azs     = 1
#   public_subnets_ids = module.vpc.public_subnets
#   private_route_table_ids = module.vpc.private_route_table_ids

#   tags = local.tags
# }
