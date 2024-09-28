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


