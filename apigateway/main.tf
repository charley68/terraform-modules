data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "${var.api_name} API Gateway"
  
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_stage" "stage" {

  for_each = var.stages
  stage_name    = each.key
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id

  # Conditionally add access_log_settings block
  dynamic "access_log_settings" {
    for_each = var.enable_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.apigateway_logs.arn
      format          = "{\"requestId\":\"$context.requestId\",\"status\":\"$context.status\",\"error\":\"$context.error.message\"}"
    }
  }

  # Define stage variables
  variables = {
    lambdaAlias = each.key
  }
}

resource "aws_api_gateway_method_settings" "settings" {

  for_each = var.stages
  rest_api_id =  aws_api_gateway_rest_api.api.id
  stage_name  = each.key
  method_path = "*/*"

  settings {
      logging_level = var.enable_logging ? "INFO" : "OFF"
      metrics_enabled = var.enable_logging
  }
}




resource "aws_api_gateway_base_path_mapping" "staging_mapping" {
  for_each = var.stages
  depends_on = [ aws_api_gateway_stage.stage ]
  api_id = aws_api_gateway_rest_api.api.id 
  stage_name  = each.key
  base_path   = each.value
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
}


resource "aws_api_gateway_usage_plan" "usagePlan" {

  depends_on = [  aws_api_gateway_stage.stage ]
  name         = "${var.api_name}-usage-plan"
  description  = "Usage Plan {var.api_name}"
  product_code = var.api_name


  dynamic "api_stages" {
    for_each = var.stages
    content {
      api_id = aws_api_gateway_rest_api.api.id
      stage  = api_stages.key
    }
  }
}

# Create an API Key - optional
resource "aws_api_gateway_api_key" "APIkey" {

  count = (var.api_key != "" ? 1 : 0)
  name = "${var.api_name}-api-key"
  value = var.api_key
  enabled     = true
}

# Associate the API key with the usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {

  count = (var.api_key != "" ? 1 : 0)
  key_id        = aws_api_gateway_api_key.APIkey[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usagePlan.id
}



# These two resources (aws_api_gateway_domain_name) and (aws_route53_record) are required together.
# aws_api_gateway_domain_name:  ->    Configures API Gateway to accept traffic for the custom domain.
# aws_route53_record:  ->             Configures Route 53 to route traffic from your custom domain to the API Gateway's Regional endpoint.
resource "aws_api_gateway_domain_name" "custom_domain" {
  domain_name = var.domain_name
  regional_certificate_arn = var.regional_certificate_arn

  # NOTE IF/WHEN WE SET THiS TO EDGE
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


#  See "aws_api_gateway_domain_name"  above
resource "aws_route53_record" "custom_domain_alias" {
  zone_id = var.zone_id
  name    = aws_api_gateway_domain_name.custom_domain.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.custom_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain.regional_zone_id
    evaluate_target_health = false
  }
}

############################################

# API Gateway Resource (Root Path)
resource "aws_api_gateway_resource" "resource" {

  for_each = { for idx, route in var.api_routes : idx => route }

  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.value.path_part
}

# API Gateway Method 
resource "aws_api_gateway_method" "method" {
  
  for_each = { for idx, route in var.api_routes : idx => route }

  rest_api_id   = aws_api_gateway_rest_api. api.id
  resource_id   = aws_api_gateway_resource.resource[each.key].id
  http_method   = each.value.http_method
  authorization = "NONE"
  api_key_required = var.api_key != "" ? true : false
}



# API Gateway Integration with Lambda 
resource "aws_api_gateway_integration" "integration" {
  
  depends_on = [ aws_api_gateway_method.method ]

  for_each = { for idx, route in var.api_routes : idx => route }

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.method[each.key].http_method 
  integration_http_method = "POST"
  type                    = each.value.lambda_arn != null ? "AWS_PROXY" : "AWS"

  credentials = each.value.credentials != null ? each.value.credentials : null
  uri = each.value.lambda_arn != null  ?  "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${each.value.lambda_arn}:$${stageVariables.lambdaAlias}/invocations" : "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_caller_identity.current.account_id}/${each.value.sqs_queue}"

  request_parameters =   each.value.sqs_queue != null  ? {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  } : null

  request_templates =  each.value.sqs_queue != null  ? {
    "application/json" = <<EOF
Action=SendMessage&MessageBody=$input.body
EOF
  } : null

  passthrough_behavior = "WHEN_NO_MATCH"
}


# Define the Integration Response
resource "aws_api_gateway_integration_response" "integrationResponse" {
  depends_on = [ aws_api_gateway_integration.integration ]

  for_each = { for idx, route in var.api_routes : idx => route }

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.method[each.key].http_method
  status_code = 200

  response_templates =   each.value.sqs_queue != null  ? {
    "application/json" = jsonencode({"message": "Message successfully posted to SQS!"})
  } : {}

  response_parameters =  each.value.sqs_queue != null  ? {
    "method.response.header.Content-Type" = "'application/json'"
  } : {}

}

#Define Method Response
resource "aws_api_gateway_method_response" "methodresponse" {
  for_each = { for idx, route in var.api_routes : idx => route }

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource[each.key].id
  http_method             = aws_api_gateway_method.method[each.key].http_method
  status_code = 200


  response_models =   each.value.sqs_queue != null  ?  {
     "application/json" = "Empty"
   } : null  

  response_parameters =  each.value.sqs_queue != null  ?  {
       "method.response.header.Content-Type" = true
  } : null
}


# Deploy the API
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.integration
  ]
}