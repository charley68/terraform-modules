# AWS Lambda Terraform module

Terraform module, which creates Lambda function and alias's but also enables the lambda permissions for APIGateway REST calls.
This is a failry specific and simplified use case for lambdas that have Versions enabled and handles Aliases.

The Lambda Alias's are created seperately rather than using a for_each for a specific reason.  The use case here is to be able to update the verion
of a lambda for preProd indepedently to prod.  As such, prod alias does not auto update if the lambda version changes.  This enables automated testing
to occur on preProd before updating prod Links  (Which will need to happen outside of Terraform - see scripts/updatelinks.py for example)

## Work In Progress - ToDo
- Option to auto create the ARN
- Version to allow multiple lambdas to be created via single module (Question if this is good design practice ? Debatable)
- Handle Layers

## Features

-  Creates Lambda with versioning enabled
-  Handles Zipping
-  Creates preProd and Prod aliases
-  Creates resource based permission for alias's 

## Usage

### Lambda Function 



```hcl
module "lambda1" {
    source               = "../lambda"

    function_name        = "lambda1"
    source_dir           = "${path.module}/lambda/lambda1"
    apigateway_arn       = "${ module.apigateway.execution_arn}/*/GET/function1"
    role_arn             = aws_iam_role.APIRole.arn
    tags                 = {project = var.project}
    
    environment_vars     = {
                REGION              = var.region
    }
}
```



## Modules

No modules.

## Resources


| Name | Type |
|------|------|
| [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [archive_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|role_arn | IAM role ARN attached to the Lambda Function. This governs both who / what can invoke your Lambda Function  | `string` | "" | yes |
|function_name | A unique name for your Lambda Function  | `string` | "" | yes |
|handler | Handler name for Lambda  | `string` | lambda_handler | no |
|runtime | Runtime to use  | `string` | python3.9 | no |
|tags | A map of tags to assign only to the lambda function  | {} | map(string) | no |
|permission_statement_id | Unique statement ID for Lambda permissions | "AllowExecutionFromAPIGateway" | string | no |
|source_dir| Source directory containing the Lambda function code| "" | string | no |
|environment_vars | Optional env vars to set for the lambda | {} | map(string) | no |
|apigateway_arn| Source ARN for API Gateway.| "" | string | yes |


## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn| The ARN of the Lambda Function |
| lambda_function_invoke_arn" | The Invoke ARN of the Lambda Function |
| lambda_function_name" | The name of the Lambda Function |


