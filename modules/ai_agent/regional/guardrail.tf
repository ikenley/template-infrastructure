#-------------------------------------------------------------------------------
# Guardrail policies
# https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html
#-------------------------------------------------------------------------------

locals {
  guardrail_content_policy_filters = toset([
    "VIOLENCE",
    "PROMPT_ATTACK",
    "MISCONDUCT",
    "HATE",
    "SEXUAL",
    "INSULTS"
  ])
  guardrail_pii_types = toset([
    "NAME",
    "PHONE",
    "EMAIL",
    "AGE",
    "USERNAME",
    "PASSWORD",
    "DRIVER_ID",
    "LICENSE_PLATE",
    "VEHICLE_IDENTIFICATION_NUMBER",
    "CREDIT_DEBIT_CARD_CVV",
    "CREDIT_DEBIT_CARD_EXPIRY",
    "CREDIT_DEBIT_CARD_NUMBER",
    "PIN",
    "INTERNATIONAL_BANK_ACCOUNT_NUMBER",
    "SWIFT_CODE",
    "IP_ADDRESS",
    "MAC_ADDRESS",
    "AWS_ACCESS_KEY",
    "AWS_SECRET_KEY",
    "US_PASSPORT_NUMBER",
    "US_SOCIAL_SECURITY_NUMBER",
    "US_INDIVIDUAL_TAX_IDENTIFICATION_NUMBER",
    "US_BANK_ACCOUNT_NUMBER",
    "US_BANK_ROUTING_NUMBER",
    "UK_UNIQUE_TAXPAYER_REFERENCE_NUMBER",
    "UK_NATIONAL_INSURANCE_NUMBER",
    "UK_NATIONAL_HEALTH_SERVICE_NUMBER",
    "CA_HEALTH_NUMBER",
    "CA_SOCIAL_INSURANCE_NUMBER"
  ])
}

resource "aws_bedrock_guardrail" "default" {
  name                      = "${local.id}-default"
  blocked_input_messaging   = "Sorry, the model cannot answer this question."
  blocked_outputs_messaging = "Sorry, the model cannot answer this question."
  description               = "${local.id} default Guardrail"

  # kms_key_arn = TODO

  content_policy_config {
    dynamic "filters_config" {
      for_each = local.guardrail_content_policy_filters
      content {
        input_strength = "HIGH"
        # PROMPT ATTACK content filter strength for response must be NONE
        output_strength = filters_config.key == "PROMPT_ATTACK" ? "NONE" : "HIGH"
        type            = filters_config.key
      }
    }
  }

  sensitive_information_policy_config {
    dynamic "pii_entities_config" {
      for_each = local.guardrail_pii_types
      content {
        action = "ANONYMIZE"
        type   = pii_entities_config.key
      }
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }
}

resource "aws_bedrock_guardrail_version" "current" {
  description   = "Current version of Bedrock Guardrails"
  guardrail_arn = aws_bedrock_guardrail.default.guardrail_arn
  skip_destroy  = true
}
