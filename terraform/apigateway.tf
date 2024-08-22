resource "aws_apigatewayv2_api" "update_visitor_vounter_api" {
  name          = "update_visitor_vounter_api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "apigateway_to_lambda_integration" {
  api_id           = aws_apigatewayv2_api.update_visitor_vounter_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Integration to updateVisitorCounter_lambda Lambda function"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.updateVisitorCounter_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_stage" "staging" {
  api_id = aws_apigatewayv2_api.update_visitor_vounter_api.id
  name   = "staging"

  auto_deploy = true

  # To display the logs in CloudWatch
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.my_api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_route" "apigateway_route_to_lambda" {
  api_id    = aws_apigatewayv2_api.update_visitor_vounter_api.id
  route_key = "POST /${aws_lambda_function.updateVisitorCounter_lambda.function_name}"

  target = "integrations/${aws_apigatewayv2_integration.apigateway_to_lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updateVisitorCounter_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.update_visitor_vounter_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "my_api_gw" {
  name = "/aws/my_api_gw/${aws_apigatewayv2_api.update_visitor_vounter_api.name}"

  retention_in_days = 90
}
