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
