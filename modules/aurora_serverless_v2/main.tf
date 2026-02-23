#------------------------------------------------------------------------------
# Aurora Serverless v2 (PostgreSQL-compatible)
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }
  }
}

locals {
  id            = "${var.namespace}-${var.env}-${var.name}"
  output_prefix = "/${var.namespace}/${var.env}/${var.name}"

  tags = merge(var.tags, {
    Environment = var.env
    is_prod     = var.is_prod
  })
}

#------------------------------------------------------------------------------
# Credentials
# master_password always applies (resets password even on snapshot restore).
# master_username is inherited from the snapshot when snapshot_identifier is set.
#------------------------------------------------------------------------------

resource "random_password" "master" {
  length           = 32
  override_special = "_"
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = local.id
  subnet_ids = var.database_subnets

  tags = local.tags
}

resource "aws_security_group" "this" {
  name        = "${local.id}-aurora"
  description = "${local.id} Aurora Serverless v2"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.id}-aurora" })
}

#------------------------------------------------------------------------------
# Aurora Cluster
#------------------------------------------------------------------------------

resource "aws_rds_cluster" "this" {
  cluster_identifier = local.id
  engine             = "aurora-postgresql"
  engine_version     = "17.4"
  engine_mode        = "provisioned"

  # When snapshot_identifier is set, master_username is inherited from the snapshot
  # and database_name is ignored by AWS. master_password resets the password post-restore.
  database_name   = var.snapshot_identifier == null ? var.database_name : null
  master_username = var.snapshot_identifier == null ? "rds_admin" : null
  master_password = random_password.master.result

  snapshot_identifier = var.snapshot_identifier

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.is_prod ? false : true
  deletion_protection     = true
  storage_encrypted       = true

  tags = local.tags
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = "${local.id}-1"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  tags = local.tags
}
