#-------------------------------------------------------------------------------
# Core EFS setup
# This is not in the regional module in order to enable replication
#-------------------------------------------------------------------------------

resource "aws_efs_file_system" "primary" {
  provider = aws.primary

  creation_token = local.id

  encrypted = true

  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(local.tags, {
    Name = local.id
  })
}

resource "aws_efs_file_system" "failover" {
  provider = aws.failover

  creation_token = local.id

  encrypted = true

  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  protection {
    replication_overwrite = "DISABLED"
  }

  tags = merge(local.tags, {
    Name = local.id
  })
}

resource "aws_efs_replication_configuration" "this" {
  provider = aws.primary

  source_file_system_id = aws_efs_file_system.primary.id

  destination {
    file_system_id = aws_efs_file_system.failover.id
    region         = local.aws_region_failover
  }
}
