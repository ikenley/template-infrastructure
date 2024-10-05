#-------------------------------------------------------------------------------
# AWS Bedrock Knowledge Base
# https://docs.aws.amazon.com/bedrock/latest/userguide/agents-kb-add.html
#-------------------------------------------------------------------------------

locals {
  vector_index_name = "${local.id}-knowledge-base-default-index"
}

data "aws_bedrock_foundation_model" "kb" {
  model_id = "amazon.titan-embed-text-v2:0"
}

resource "aws_bedrockagent_knowledge_base" "knowledge_base" {
  name     = local.id
  role_arn = local.knowledge_base_role_arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.kb.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = var.bedrock_user_secret_arn
      resource_arn           = var.rds_cluster_arn
      database_name          = "postgres"
      table_name             = "bedrock_integration.bedrock_kb"
      field_mapping {
        primary_key_field = "id"
        vector_field      = "embedding"
        text_field        = "chunks"
        metadata_field    = "metadata"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy.knowledge_base[0]
  ]
}

resource "aws_bedrockagent_data_source" "knowledge_base" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.knowledge_base.id
  name              = "${local.id}-data-source"

  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = data.aws_ssm_parameter.s3_knowledge_base_arn.value
    }
  }
}

resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  agent_id             = aws_bedrockagent_agent.this.id
  description          = file("${path.module}/prompt_templates/kb_instruction.txt")
  knowledge_base_id    = aws_bedrockagent_knowledge_base.knowledge_base.id
  knowledge_base_state = "ENABLED"
}

#-------------------------------------------------------------------------------
# Perform initial sync of data store to vector store
#-------------------------------------------------------------------------------
resource "null_resource" "sync_kb" {
  triggers = {
    knowledge_base_id = aws_bedrockagent_knowledge_base.knowledge_base.id
    version           = "1.0.3" # arbitrary flag to trigger re-runs
  }
  provisioner "local-exec" {
    command = <<-EOF
aws bedrock-agent start-ingestion-job --data-source-id $DATA_SOURCE_ID --knowledge-base-id $KNOWLEDGE_BASE_ID
			EOF

    environment = {
      DATA_SOURCE_ID    = aws_bedrockagent_data_source.knowledge_base.data_source_id
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.knowledge_base.id
    }

    interpreter = ["bash", "-c"]
  }
}
