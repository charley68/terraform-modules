output "endpoints" {
    description = "API Gateway endpoints"
    value = module.apigateway.stage_invoke_urls
}
