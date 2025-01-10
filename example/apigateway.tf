
/**
    module to create APIGateway along with Stages and API Routes. Note deployment
    will only happen to none prod Stages to allow testing to be done. 

    This module will create an A record in Route53 for your domain using the format
    api.yourdomain.com.  This will be the endpoint for your API Gateway along with 
    the respective Stage Paths:

    example:  api.mydomain.com/rest1 for the Prod alias
              api.mydomain.com/preProd/rest1 for the PreProd alias

**/

module "apigateway" {
    source = "../apigateway"
    api_name = var.project                     # The Project Name
    #api_key = var.api_key_value               # The API Key Value (optional)
    enable_logging = true                      # Enable API Logging
    stages = {"prod"="", "preProd"="preProd"}  # Alias stages and their Paths 
    domain_name = var.domain_name              # your Route53 Domain name
    regional_certificate_arn = var.SSLCertificate  # SSL Certificate for Route53
    zone_id = var.hosted_zone_id               # The Hosted Zone ID to create api.domain
    region = var.region


    api_routes = [
       {path_part = "function1", http_method = "GET", lambda_arn = module.lambda1.lambda_function_arn}
    ]
} 
