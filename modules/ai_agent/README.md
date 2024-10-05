# ai-agent

Demonstrates how to create an [Amazon Bedrock Agent](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html).This includes:

- A [Knowledge Base](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-kb-add.html) to enrich the base model with proprietary data
- [Action Groups](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-action-create.html) for adding custom application behavior (as if the Agent could make internal API calls).

This will ulimately be consumed by [ai-app](https://github.com/ikenley/ai-app) on https://ai.ikenley.com/ai

Special thanks to [acwwat for this steller example which provided the base scaffolding for some of the Terraform resources](https://github.com/acwwat/terraform-amazon-bedrock-agent-example/tree/main)

---

```
aws bedrock list-foundation-models
aws rds describe-db-engine-versions --engine aurora-postgresql --query '*[].[EngineVersion]' --output text --region us-east-1
aws rds describe-db-cluster-parameters --db-cluster-parameter-group-name default.aurora-postgresql16
aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily"
aws bedrock get-guardrail --guardrail-identifier uizv5916nmkj --guardrail-version 1 > ./builds/guardrail.json
```
