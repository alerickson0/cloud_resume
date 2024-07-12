output "cf_domain_name_url" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "lambda_function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.updateVisitorCounter_lambda.function_name
}

output "api_gw_base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.staging.invoke_url
}
