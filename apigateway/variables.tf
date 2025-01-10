
variable "api_name" {
  description = "Name of API"
  type        = string
}

variable "enable_logging" {
  description = "Enable API logging"
  type        = bool
  default     = false
}

variable "stages" {
  description = "API Gateway Stages"
  type        = map(string)
}

variable "domain_name" {
  description = "Route53 API Domain Name"
  type        = string
}

variable "regional_certificate_arn" {
    description = "Route53 API Domain Name"
    type        = string
}

variable "zone_id" {
    description = "Route 53 ZoneID"
    type = string
}

variable "api_key" {
    description = "API Key"
    type = string
    default = ""
}


variable "api_routes" {
  description = "List of API Gateway routes with associated HTTP method and Lambda ARN"
  type = list(
    object({
      path_part   = string
      http_method = string

      lambda_arn = optional(string, null)
      sqs_queue  = optional(string, null)
      credentials = optional(string, null)
    })
  )
}

variable "region" {
  description = "AWS Region"
  type        = string
}


  /*validation {
    condition = alltrue([
      for route in var.api_routes : 
        (can(route.lambda_arn) && !can(route.sqs_queue)) || 
        (can(route.sqs_queue) && !can(route.lambda_arn))
    ])
    error_message = "Each route must define exactly one of `lambda_arn` or `sqs_queue`, but not both."
  }*/
