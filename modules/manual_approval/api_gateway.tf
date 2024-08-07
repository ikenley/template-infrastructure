#-------------------------------------------------------------------------------
# API gateway which accepts approve/reject requests
#-------------------------------------------------------------------------------

locals {
  api_gateway_id = "${local.id}-api-gateway"
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name             = local.api_gateway_id
  description      = "HTTP Endpoint backed by API Gateway and Lambda"
  fail_on_warnings = true
}

resource "aws_api_gateway_resource" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "execution"
}

resource "aws_api_gateway_method" "api_gateway" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway.id
  authorization = "NONE"
  http_method   = "GET"
  // CF Property(Integration) = {
  //   Type = "AWS"
  //   IntegrationHttpMethod = "POST"
  //   Uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_approval_function.arn}/invocations"
  //   IntegrationResponses = [
  //     {
  //       StatusCode = 302
  //       ResponseParameters = {
  //         method.response.header.Location = "integration.response.body.headers.Location"
  //       }
  //     }
  //   ]
  //   RequestTemplates = {
  //     application/json = "{
  //   "body" : $input.json('$'),
  //   "headers": {
  //     #foreach($header in $input.params().header.keySet())
  //     "$header": "$util.escapeJavaScript($input.params().header.get($header))" #if($foreach.hasNext),#end
  // 
  //     #end
  //   },
  //   "method": "$context.httpMethod",
  //   "params": {
  //     #foreach($param in $input.params().path.keySet())
  //     "$param": "$util.escapeJavaScript($input.params().path.get($param))" #if($foreach.hasNext),#end
  // 
  //     #end
  //   },
  //   "query": {
  //     #foreach($queryParam in $input.params().querystring.keySet())
  //     "$queryParam": "$util.escapeJavaScript($input.params().querystring.get($queryParam))" #if($foreach.hasNext),#end
  // 
  //     #end
  //   }  
  // }
  // "
  //   }
  // }
  // CF Property(MethodResponses) = [
  //   {
  //     StatusCode = 302
  //     ResponseParameters = {
  //       method.response.header.Location = true
  //     }
  //   }
  // ]
}

resource "aws_api_gateway_integration" "api_gateway" {
  http_method = aws_api_gateway_method.api_gateway.http_method
  resource_id = aws_api_gateway_resource.api_gateway.id
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.receive_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}

resource "aws_iam_role" "api_gateway" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "apigateway.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway" {
  role       = aws_iam_role.api_gateway.name
  policy_arn = aws_iam_policy.api_gateway.arn
}

resource "aws_iam_policy" "api_gateway" {
  name        = local.api_gateway_id
  path        = "/"
  description = "Main policy for ${local.api_gateway_id}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:*:*"
      }
    ]
  })
}

resource "aws_api_gateway_stage" "api_gateway" {
  deployment_id = aws_api_gateway_deployment.api_gateway.id
  // CF Property(MethodSettings) = [
  //   {
  //     DataTraceEnabled = true
  //     HttpMethod = "*"
  //     LoggingLevel = "INFO"
  //     ResourcePath = "/*"
  //   }
  // ]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "manual-approve"
}

resource "aws_api_gateway_method_settings" "api_gateway" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway.id}"
  stage_name  = "${aws_api_gateway_stage.api_gateway.stage_name}"
  method_path = "*/*"
  settings {
    logging_level = "INFO"
    data_trace_enabled = true
    metrics_enabled = true
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "api_gateway_execution/${aws_api_gateway_rest_api.api_gateway.id}/${aws_api_gateway_stage.api_gateway.stage_name}"
  retention_in_days = 7
  # ... potentially other configuration ...
}

resource "aws_api_gateway_deployment" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "DummyStage"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api_gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "lambda_api_gateway_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = module.receive_lambda.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"
}
