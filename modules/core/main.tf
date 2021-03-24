
# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main"

  cidr = var.cidr 

  azs                 = var.azs
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  database_subnets    = var.database_subnets
  # elasticache_subnets = ["10.214.158.0/24", "10.214.159.0/24", "10.214.160.0/24"]
  # elasticache_subnet_suffix  = "elasticache"
  # redshift_subnets    = ["10.214.168.0/24", "10.214.169.0/24", "10.214.170.0/24"]
  # redshift_subnet_suffix  = "redshift"
  # intra_subnets       = ["10.214.178.0/24", "10.214.179.0/24", "10.214.180.0/24"]
  # intra_subnet_suffix  = "intra"

  public_subnet_tags = {
    Tier = "public"
    "kubernetes.io/cluster/impact-eks" = "shared"
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    Tier = "private"
    "kubernetes.io/cluster/impact-eks" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
  database_subnet_tags = {
    Tier = "database"
  }

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # enable_classiclink             = true
  # enable_classiclink_dns_support = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # customer_gateways = {
  #   IP1 = {
  #     bgp_asn    = 65112
  #     ip_address = "1.2.3.4"
  #   },
  #   IP2 = {
  #     bgp_asn    = 65112
  #     ip_address = "5.6.7.8"
  #   }
  # }

  # enable_vpn_gateway = true

  # enable_dhcp_options              = true
  # dhcp_options_domain_name         = "service.consul"
  # dhcp_options_domain_name_servers = ["127.0.0.1", "10.10.0.2"]

  # VPC endpoint for S3
  # enable_s3_endpoint = true

  # VPC endpoint for DynamoDB
  # enable_dynamodb_endpoint = true

  # VPC endpoint for SSM
  # enable_ssm_endpoint              = true
  # ssm_endpoint_private_dns_enabled = true
  # ssm_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # # VPC endpoint for SSMMESSAGES
  # enable_ssmmessages_endpoint              = true
  # ssmmessages_endpoint_private_dns_enabled = true
  # ssmmessages_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for EC2
  # enable_ec2_endpoint              = true
  # ec2_endpoint_private_dns_enabled = true
  # ec2_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # VPC Endpoint for EC2MESSAGES
  # enable_ec2messages_endpoint              = true
  # ec2messages_endpoint_private_dns_enabled = true
  # ec2messages_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # VPC Endpoint for ECR API
  # enable_ecr_api_endpoint              = true
  # ecr_api_endpoint_private_dns_enabled = true
  # ecr_api_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # # VPC Endpoint for ECR DKR
  # enable_ecr_dkr_endpoint              = true
  # ecr_dkr_endpoint_private_dns_enabled = true
  # ecr_dkr_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # VPC endpoint for KMS
  # enable_kms_endpoint              = true
  # kms_endpoint_private_dns_enabled = true
  # kms_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # VPC endpoint for ECS
  # enable_ecs_endpoint              = true
  # ecs_endpoint_private_dns_enabled = true
  # ecs_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # # VPC endpoint for ECS telemetry
  # enable_ecs_telemetry_endpoint              = true
  # ecs_telemetry_endpoint_private_dns_enabled = true
  # ecs_telemetry_endpoint_security_group_ids  = [
  #   data.aws_security_group.default.id, 
  #   module.internal_all_security_group.this_security_group_id
  # ]

  # VPC endpoint for CodeDeploy
  # enable_codedeploy_endpoint              = true
  # codedeploy_endpoint_private_dns_enabled = true
  # codedeploy_endpoint_security_group_ids  = [data.aws_security_group.default.id]

  # # VPC endpoint for CodeDeploy Commands Secure
  # enable_codedeploy_commands_secure_endpoint              = true
  # codedeploy_commands_secure_endpoint_private_dns_enabled = true
  # codedeploy_commands_secure_endpoint_security_group_ids  = [data.aws_security_group.default.id]

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

  # vpc_endpoint_tags = {
  #   #Name      = "vpc-impact"
  # }
}

# ------------------------------------------------------------------------------
# S3 buckets
# ------------------------------------------------------------------------------

module "s3_bucket_codepipeline" {
  source = "../s3_bucket"

  bucket_name_suffix = "code-pipeline"

  tags = local.tags
}

# ------------------------------------------------------------------------------
# Docker credentials
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "docker_username" {
  name  = "/docker/username"
  type  = "String"
  value = var.docker_username

  tags = local.tags
}

resource "aws_ssm_parameter" "docker_password" {
  name  = "/docker/password"
  type  = "SecureString"
  value = var.docker_password

  tags = local.tags
}