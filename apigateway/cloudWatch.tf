resource "aws_cloudwatch_log_group" "apigateway_logs" {
  name = "/aws/apigateway/${var.api_name}-api-access-logs"
  retention_in_days = 7  # Adjust as needed
}