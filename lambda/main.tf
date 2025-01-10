
resource "aws_lambda_function" "lambda_function" {
  
  function_name    = var.function_name
  filename         = data.archive_file.lambda_zip.output_path


  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  publish          = true
  role             = var.role_arn

  runtime          = var.runtime
  handler          = "${var.function_name}.${var.handler}"


  environment {
    variables = var.environment_vars
  }

  tags = var.tags
}


# In order to avoid updating PROD alias each time preProd changes, we do 
# the alias's as seperate ressources.
resource "aws_lambda_alias" "lambda_alias_preProd" {

  #for_each =   toset(var.alias_names)
  name  = "preProd"

  function_name    = aws_lambda_function.lambda_function.function_name
  function_version = aws_lambda_function.lambda_function.version
}


# For prod, we ignore changes to the function version as we want to update
# the alias outside of TF after doing some preProd testing.
resource "aws_lambda_alias" "lambda_alias_prod" {

  #for_each =   toset(var.alias_names)
  name  = "prod"

  function_name    = aws_lambda_function.lambda_function.function_name
  function_version = aws_lambda_function.lambda_function.version
  

  lifecycle {
    ignore_changes  = [function_version] 
  }

}

resource "aws_lambda_permission" "lambda_permission_preProd" {
  depends_on       = [aws_lambda_alias.lambda_alias_preProd]


  statement_id     = "AllowExecutionFromAPIGateway"
  action           = "lambda:InvokeFunction"
  function_name    = "${aws_lambda_function.lambda_function.function_name}"
  principal        = "apigateway.amazonaws.com"
  source_arn       = var.apigateway_arn
  qualifier = "preProd"
}

resource "aws_lambda_permission" "lambda_permission_prod" {
  depends_on       = [aws_lambda_alias.lambda_alias_prod]


  statement_id     = "AllowExecutionFromAPIGateway"
  action           = "lambda:InvokeFunction"
  function_name    = "${aws_lambda_function.lambda_function.function_name}"
  principal        = "apigateway.amazonaws.com"
  source_arn       = var.apigateway_arn
  qualifier = "prod"
}



data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.source_dir}/lambda.zip"
}