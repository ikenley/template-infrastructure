#-------------------------------------------------------------------------------
# Aurora RDS cluster
# In the root module to enable future replication
# Terraform source based off of:
# https://github.com/terraform-aws-modules/terraform-aws-rds-aurora/blob/master/main.tf
#-------------------------------------------------------------------------------

locals {
  rds_id = "${local.id}-rds"
}

# Sourced from


#-------------------------------------------------------------------------------
# DB Subnet Group
#-------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  provider = aws.primary

  name        = local.rds_id
  description = "For Aurora cluster ${local.rds_id}"
  subnet_ids  = local.database_subnets

  tags = var.tags
}

#-------------------------------------------------------------------------------
# Cluster
#-------------------------------------------------------------------------------

resource "aws_rds_cluster" "this" {
  provider = aws.primary

  cluster_identifier = local.rds_id

  #db_cluster_instance_class       = "db.t3.small" # TODO determine correct sizing
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id
  enable_http_endpoint            = true
  engine                          = "aurora-postgresql"
  engine_version                  = "16.4"

  availability_zones     = var.primary_rds_availability_zones
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_kb.id]

  #allocated_storage           = var.allocated_storage
  #allow_major_version_upgrade = false
  #apply_immediately                   = var.apply_immediately
  backup_retention_period   = 5
  deletion_protection       = false # TODO change this for final version
  copy_tags_to_snapshot     = true
  final_snapshot_identifier = "${local.rds_id}-${random_string.snapshot_identifier_suffix.result}"

  #kms_key_id = var.kms_key_id # TODO change this foro final version

  #backtrack_window                    = local.backtrack_window
  #ca_certificate_identifier           = var.cluster_ca_cert_identifier
  #cluster_identifier_prefix           = var.cluster_use_name_prefix ? "${var.name}-" : null
  #cluster_members                     = var.cluster_members
  #database_name                       = var.is_primary_cluster ? var.database_name : null
  #db_instance_parameter_group_name = var.allow_major_version_upgrade ? var.db_cluster_db_instance_parameter_group_name : null
  #delete_automated_backups            = var.delete_automated_backups

  #enable_global_write_forwarding      = var.enable_global_write_forwarding
  #enable_local_write_forwarding       = var.enable_local_write_forwarding
  enabled_cloudwatch_logs_exports = ["postgresql"]


  #engine_mode                         = var.engine_mode
  #engine_lifecycle_support            = var.engine_lifecycle_support

  #global_cluster_identifier           = var.global_cluster_identifier
  #domain                              = var.domain
  #domain_iam_role_name                = var.domain_iam_role_name
  iam_database_authentication_enabled = true
  storage_encrypted                   = true

  # iam_roles has been removed from this resource and instead will be used with aws_rds_cluster_role_association below to avoid conflicts per docs
  #iops                                  = var.iops

  manage_master_user_password = true
  #master_user_secret_kms_key_id         = null # TODO change this for final version
  #master_password                       = var.is_primary_cluster && !var.manage_master_user_password ? var.master_password : null
  master_username = "rds_admin"

  #network_type                          = var.network_type

  performance_insights_enabled = true
  # performance_insights_kms_key_id       = var.cluster_performance_insights_kms_key_id # TODO change this for final version
  performance_insights_retention_period = 31

  #port                          = local.port
  preferred_backup_window      = "04:00-06:00"
  preferred_maintenance_window = "sat:01:00-sat:03:30"

  #replication_source_identifier = var.replication_source_identifier

  #skip_final_snapshot    = var.skip_final_snapshot
  #snapshot_identifier    = var.snapshot_identifier
  #source_region          = var.source_region

  #storage_type           = var.storage_type
  tags = local.tags

  # timeouts {
  #   create = try(var.cluster_timeouts.create, null)
  #   update = try(var.cluster_timeouts.update, null)
  #   delete = try(var.cluster_timeouts.delete, null)
  # }

  # lifecycle {
  #   ignore_changes = [
  #     # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#replication_source_identifier
  #     # Since this is used either in read-replica clusters or global clusters, this should be acceptable to specify
  #     replication_source_identifier,
  #     # See docs here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster#new-global-cluster-from-existing-db-cluster
  #     global_cluster_identifier,
  #     snapshot_identifier,
  #   ]
  # }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "random_string" "snapshot_identifier_suffix" {
  length  = 10
  special = false

  keepers = {
    "version" = "1.0.1"
  }
}

#-------------------------------------------------------------------------------
# Cluster Instance(s)
#-------------------------------------------------------------------------------

resource "aws_rds_cluster_instance" "this" {
  provider = aws.primary

  cluster_identifier = aws_rds_cluster.this.id
  identifier         = "${local.rds_id}-primary"

  engine                  = "aurora-postgresql"
  engine_version          = "16.4"
  instance_class          = "db.r6g.large" # TODO determine optimal class
  db_parameter_group_name = aws_db_parameter_group.this.id
  db_subnet_group_name    = aws_db_subnet_group.this.name

  availability_zone   = local.azs[0]
  publicly_accessible = false

  apply_immediately = false

  copy_tags_to_snapshot = true

  monitoring_interval = 10
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  performance_insights_enabled = true
  #performance_insights_kms_key_id       = # TODO
  performance_insights_retention_period = 31

  # preferred_backup_window - is set at the cluster level and will error if provided here
  preferred_maintenance_window = "sun:01:00-sun:03:30"
  #promotion_tier               = try(each.value.promotion_tier, null)

  tags = local.tags

  # timeouts {
  #   create = try(var.instance_timeouts.create, null)
  #   update = try(var.instance_timeouts.update, null)
  #   delete = try(var.instance_timeouts.delete, null)
  # }
}

#-------------------------------------------------------------------------------
# Cluster IAM Roles
#-------------------------------------------------------------------------------

# resource "aws_rds_cluster_role_association" "this" {
#   for_each = { for k, v in var.iam_roles : k => v if local.create }

#   db_cluster_identifier = aws_rds_cluster.this[0].id
#   feature_name          = each.value.feature_name
#   role_arn              = each.value.role_arn
# }

#-------------------------------------------------------------------------------
# Enhanced Monitoring
#-------------------------------------------------------------------------------

data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  provider = aws.primary

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  provider = aws.primary

  name        = "${local.rds_id}-enhanced-monitoring"
  description = "${local.rds_id} enhanced monitoring role"
  path        = "/"

  assume_role_policy = data.aws_iam_policy_document.monitoring_rds_assume_role.json
  # managed_policy_arns   = var.iam_role_managed_policy_arns
  # permissions_boundary  = var.iam_role_permissions_boundary
  # force_detach_policies = var.iam_role_force_detach_policies
  # max_session_duration  = var.iam_role_max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  provider = aws.primary

  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:${data.aws_partition.primary.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#-------------------------------------------------------------------------------
# DNS
#-------------------------------------------------------------------------------
data "aws_route53_zone" "base_domain" {
  name         = "${var.base_domain}."
  private_zone = false
}

resource "aws_route53_record" "rds_kb_writer" {
  provider = aws.primary

  zone_id = data.aws_route53_zone.base_domain.zone_id
  name    = "${local.rds_id}-writer.${var.base_domain}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_rds_cluster.this.endpoint]
}

resource "aws_route53_record" "rds_kb_reader" {
  provider = aws.primary

  zone_id = data.aws_route53_zone.base_domain.zone_id
  name    = "${local.rds_id}-reader.${var.base_domain}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_rds_cluster.this.reader_endpoint]
}

#-------------------------------------------------------------------------------
# Security Group
#-------------------------------------------------------------------------------

resource "aws_security_group" "rds_kb" {
  provider = aws.primary

  name        = local.rds_id
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  description = "Control traffic to/from RDS Aurora ${local.rds_id}"

  tags = merge(local.tags, { Name = local.rds_id })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_kb" {
  provider = aws.primary

  security_group_id = aws_security_group.rds_kb.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"

  cidr_blocks = [data.aws_ssm_parameter.vpc_cidr.value]
  description = "Allow internal connections"

  #source_security_group_id = # TODO consider refactoring to be based on source_security_group_id
}

#-------------------------------------------------------------------------------
# Cluster Parameter Group
#-------------------------------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "this" {
  provider = aws.primary

  name        = local.rds_id
  description = "Cluster parameters for ${local.rds_id}"
  family      = "aurora-postgresql16"

  # parameter {
  #   name  = "character_set_server"
  #   value = "utf8"
  # }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

#-------------------------------------------------------------------------------
# DB Parameter Group
#-------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  provider = aws.primary

  name = local.rds_id

  description = "Instance parameters for ${local.rds_id}"
  family      = "aurora-postgresql16"

  # parameter {
  #   name  = "character_set_server"
  #   value = "utf8"
  # }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

#-------------------------------------------------------------------------------
# CloudWatch Log Group
#-------------------------------------------------------------------------------

# Log groups will not be created if using a cluster identifier prefix
resource "aws_cloudwatch_log_group" "this" {
  provider = aws.primary

  name              = "/aws/rds/cluster/${local.rds_id}"
  retention_in_days = 365
  #kms_key_id        = var.cloudwatch_log_group_kms_key_id # TODO 

  tags = local.tags
}

#-------------------------------------------------------------------------------
# Cluster Activity Stream
#-------------------------------------------------------------------------------

# resource "aws_rds_cluster_activity_stream" "this" {
#   count = local.create && var.create_db_cluster_activity_stream ? 1 : 0

#   resource_arn                        = aws_rds_cluster.this[0].arn
#   mode                                = var.db_cluster_activity_stream_mode
#   kms_key_id                          = var.db_cluster_activity_stream_kms_key_id
#   engine_native_audit_fields_included = var.engine_native_audit_fields_included

#   depends_on = [aws_rds_cluster_instance.this]
# }

#-------------------------------------------------------------------------------
# Managed Secret Rotation
#-------------------------------------------------------------------------------

resource "aws_secretsmanager_secret_rotation" "this" {
  provider = aws.primary

  secret_id = aws_rds_cluster.this.master_user_secret[0].secret_arn

  rotation_rules {
    automatically_after_days = 30
    duration                 = "3h"
  }
}

#-------------------------------------------------------------------------------
# Bedrock user Secret
# https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html
#-------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "bedrock_user" {
  provider = aws.primary

  name = "${local.id}-bedrock-user"

  #kms_key_id = "TODO"

  # TODO
  # replica {
  #   region = "us-west-2"
  #   kms_key_id = ""
  # }

  tags = merge(local.tags, {})
}



resource "aws_secretsmanager_secret_version" "bedrock_user" {
  provider = aws.primary

  secret_id = aws_secretsmanager_secret.bedrock_user.id

  secret_string = jsonencode({
    "engine" : "postgres",
    "host" : aws_route53_record.rds_kb_writer.name,
    "username" : "bedrock_user",
    "password" : random_password.bedrock_user.result,
    "dbname" : "postgres",
    "port" : 5432,
    "masterarn" : aws_rds_cluster.this.master_user_secret[0].secret_arn,
    "dbClusterIdentifier" : aws_rds_cluster_instance.this.identifier,
    "dbInstanceIdentifier" : aws_rds_cluster.this.id
  })
}

resource "random_password" "bedrock_user" {
  length           = 64
  special          = true
  override_special = "_"
}

#-------------------------------------------------------------------------------
# Run initial SQL scripts to configure vector store
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
# Original inspiration for this null_resource from:
# https://advancedweb.hu/how-to-run-sql-scripts-against-the-rds-data-api-with-terraform/
# This script should only perform the minimum required to get started
# Subsequent SQL commands should use SQL migrations (e.g. Flyway)
#-------------------------------------------------------------------------------

# Create the bedrock_user role in Postgres
resource "null_resource" "db_setup_user" {
  triggers = {
    version = "1.0.3" # arbitrary flag to trigger re-runs
  }
  provisioner "local-exec" {
    command = <<-EOF
function exec_sql() {
    aws rds-data execute-statement --resource-arn "$DB_ARN" --database  "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "$1"
}

SQL="create role bedrock_user with password '$BEDROCK_USER_PW' login;"
echo "SQL=$SQL"
echo aws rds-data execute-statement --resource-arn "$DB_ARN" --database "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "$SQL"
aws rds-data execute-statement --resource-arn "$DB_ARN" --database  "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "$SQL"
			EOF

    environment = {
      DB_ARN          = aws_rds_cluster.this.arn
      DB_NAME         = "postgres"
      SECRET_ARN      = aws_rds_cluster.this.master_user_secret[0].secret_arn
      BEDROCK_USER_PW = random_password.bedrock_user.result
    }

    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_rds_cluster_instance.this]
}

# Create the minimal schema required for Bedrock to use a vector store
# This is separate from db_setup_user to allow logging of nonsensitive details
resource "null_resource" "db_setup_schema" {
  triggers = {
    version = "1.0.3" # arbitrary flag to trigger re-runs
  }
  provisioner "local-exec" {
    command = <<-EOF
function exec_sql() {
    aws rds-data execute-statement --resource-arn "$DB_ARN" --database  "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "$1"
}

exec_sql "create extension if not exists vector;"
exec_sql "select extversion from pg_extension where extname='vector';"

exec_sql "create schema if not exists bedrock_integration;"

exec_sql "create role bedrock_integration_reader;"
exec_sql "create role bedrock_integration_writer;"
exec_sql "grant bedrock_integration_reader to bedrock_integration_writer;"

exec_sql "grant usage on schema bedrock_integration to bedrock_integration_reader;"
exec_sql "alter default privileges in schema bedrock_integration grant select on tables to bedrock_integration_reader;"
exec_sql "alter default privileges grant usage, select on sequences to bedrock_integration_reader;"
exec_sql "alter default privileges in schema bedrock_integration grant insert, update, delete on tables to bedrock_integration_writer;"

exec_sql "grant bedrock_integration_writer to bedrock_user;"
exec_sql "grant all on schema bedrock_integration to bedrock_user;"

exec_sql "create table bedrock_integration.bedrock_kb (id uuid primary key, embedding vector(1024), chunks text, metadata json);"
exec_sql "create index on bedrock_integration.bedrock_kb using hnsw (embedding vector_cosine_ops);"
exec_sql "create index on bedrock_integration.bedrock_kb using hnsw (embedding vector_cosine_ops) with (ef_construction=256);"
			EOF

    environment = {
      DB_ARN     = aws_rds_cluster.this.arn
      DB_NAME    = "postgres"
      SECRET_ARN = aws_rds_cluster.this.master_user_secret[0].secret_arn
    }

    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.db_setup_user]
}
