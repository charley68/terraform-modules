

variable "role_arn" {
  description = "IAM Role ARN for the Lambda function."
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "handler" {
  description = "The handler for the Lambda function."
  type        = string
  default     = "lambda_handler"
}

variable "runtime" {
  description = "The runtime for the Lambda function."
  type        = string
  default     = "python3.9"
}

variable "tags" {
  description = "Tags to apply to the Lambda function."
  type        = map(string)
  default     = {}
}


variable "source_dir" {
  description = "Source directory containing the Lambda function code."
  type        = string
}

variable "environment_vars" {
  description = "Optional env vars to set for the lambda"
  type = map(string)
  default = {}
}


variable "apigateway_arn" {
  description = "Source ARN for API Gateway."
  type        = string
}