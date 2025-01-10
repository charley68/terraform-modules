
variable "region" {
    type        = string
}

variable "project" {
    type = string
}

variable "domain_name" {
  description = "The standard domain name. in our case, we will create an A record for api.xxx.com"
  type = string
}

variable "hosted_zone_id" {
    description = "THe Hosted Zone for Route53 so we can create an A record for api.mydomain.com"
    type  = string
}

variable "SSLCertificate" {
    type = string
}

variable "api_key_value" {
  description = "The hardcoded API key value"
  type        = string
}

