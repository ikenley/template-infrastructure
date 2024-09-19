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
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = local.vector_index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy.knowledge_base[0],
    aws_iam_role_policy.knowledge_base_open_search[0],
    opensearch_index.knowledge_base,
    time_sleep.aws_iam_role_policy_knowledge_base
  ]
}


#-------------------------------------------------------------------------------
# OpenSearch Serverless
# TODO consider converting this to Aurora PostgreSQL
#-------------------------------------------------------------------------------

locals {
  kb_oss_collection_name = "${local.id}-collection"
}

resource "aws_opensearchserverless_access_policy" "knowledge_base" {
  name        = local.kb_oss_collection_name
  description = "Knowledge base access policy"
  type        = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${local.kb_oss_collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        local.knowledge_base_role_arn,
        data.aws_caller_identity.current.arn,
        # TODO delete this
        "arn:aws:iam::924586450630:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AWSAdministratorAccess_ef1dc232c2e58f3b"
      ]
    }
  ])

  # TODO delete this
  lifecycle {
    ignore_changes = [policy]
  }
}


resource "aws_opensearchserverless_security_policy" "knowledge_base_collection" {
  name = "${local.kb_oss_collection_name}-coll"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${local.kb_oss_collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

# Allow public internet access
# TODO either modify to use VPC endpoint or switch to Aurora PostgreSQL
resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  name = "${local.kb_oss_collection_name}-net"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${local.kb_oss_collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = local.kb_oss_collection_name
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_access_policy.knowledge_base,
    aws_opensearchserverless_security_policy.knowledge_base_collection,
    aws_opensearchserverless_security_policy.knowledge_base_network
  ]
}

#-------------------------------------------------------------------------------
# OCreate index for OpenSearch Serverless collection
# TODO consider converting this to Aurora PostgreSQL
#-------------------------------------------------------------------------------

provider "opensearch" {
  url         = aws_opensearchserverless_collection.knowledge_base.collection_endpoint
  healthcheck = false
}

resource "opensearch_index" "knowledge_base" {
  name                           = local.vector_index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.knowledge_base]
}

# Since Terraform creates resources in quick succession, 
# there is a chance that the configuration of the knowledge base service role 
# is not propagated across AWS endpoints before it is used by the knowledge base 
# during its creation, resulting in temporary permission issues.
# https://blog.avangards.io/how-to-manage-an-amazon-bedrock-knowledge-base-using-terraform#heading-defining-the-knowledge-base-resource
resource "time_sleep" "aws_iam_role_policy_knowledge_base" {
  create_duration = "20s"
  depends_on      = [aws_iam_role_policy.knowledge_base]
}
