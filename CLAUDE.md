# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terraform infrastructure-as-code repository for AWS web hosting infrastructure. Each top-level directory corresponds to a different environment/AWS account, except for the shared `modules` directory.

## Repository Structure

- `modules/` - Reusable Terraform modules (where most work happens)
- `dev/` - Development environment configurations that consume modules
- Environment directories primarily maintain state and environment-specific tags

## Common Commands

```bash
# Initialize Terraform (run from environment directory, e.g., dev/core)
terraform init

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Note: Most environments require sensitive variables passed via .tfvars files
# (which are gitignored) or environment variables
```

## AWS Profile Configuration

The codebase uses AWS CLI profiles for authentication. The dev environment uses `terraform-dev` profile:
```bash
aws configure --profile terraform-dev
```

## Key Modules

- **core** - Foundational resources: VPC networking, S3 buckets, ECS cluster, Route53, SES, CodeArtifact, SFTP. Supports multi-region (primary/failover) with `spend_money` flag to control expensive services.
- **application** - End-to-end ECS Fargate application hosting with CodePipeline CI/CD
- **ai_agent** - Amazon Bedrock Agent with Knowledge Base (RDS/OpenSearch) and Action Groups
- **ai_app** - AI application infrastructure with Lambda job runners
- **auth_service** - Cognito-based authentication (supports Google OAuth)
- **network_hub** - Cross-account networking hub with AWS Network Firewall for centralized ingress/egress

## Architecture Patterns

- Modules use `namespace`, `env`, `name` variables for consistent resource naming
- `spend_money` variable toggles expensive services (NAT Gateway, VPN, bastion) for cost control
- S3 backend for Terraform state with DynamoDB locking (configured in `remote_state` module)
- Multi-region support via provider aliases (`aws.primary`, `aws.failover`)
- ECS Fargate for containerized applications with ALB
- CodePipeline/CodeBuild for CI/CD

## Account Details

- Development (924586450630): CIDR 10.0.0.0/18
- Production: CIDR 10.0.64.0/18 (TODO)
