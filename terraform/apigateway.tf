resource "aws_apigatewayv2_api" "update_visitor_vounter_api" {
  name          = "update_visitor_vounter_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "apigateway_to_lambda_integration" {
  api_id           = aws_apigatewayv2_api.update_visitor_vounter_api.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  description               = "Integration to updateVisitorCounter_lambda Lambda function"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.updateVisitorCounter_lambda.arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_stage" "staging" {
  api_id = aws_apigatewayv2_api.update_visitor_vounter_api.id
  name   = "staging"

  auto_deploy = true
}

resource "aws_apigatewayv2_route" "apigateway_route_to_lambda" {
  api_id    = aws_apigatewayv2_api.update_visitor_vounter_api.id
  route_key = "POST /${aws_lambda_function.updateVisitorCounter_lambda.function_name}"

  target = aws_apigatewayv2_integration.apigateway_to_lambda_integration.id
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updateVisitorCounter_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.update_visitor_vounter_api.execution_arn}/*/*"
}
