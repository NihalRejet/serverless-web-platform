resource "aws_apigatewayv2_api" "swp-api" {
  name          = "swp-http-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
  }
}

resource "aws_apigatewayv2_integration" "swp-api" {
  api_id                 = aws_apigatewayv2_api.swp-api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.swp_counter.invoke_arn
}

resource "aws_apigatewayv2_route" "swp-api-route" {
  api_id    = aws_apigatewayv2_api.swp-api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.swp-api.id}"
}

resource "aws_apigatewayv2_stage" "swp-api-stage" {
  api_id      = aws_apigatewayv2_api.swp-api.id
  name        = "$default"
  auto_deploy = true
}

# Grant API Gateway permission to invoke Lambda
resource "aws_lambda_permission" "swp-api-permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.swp_counter.function_name
  principal     = "apigateway.amazonaws.com"

  # Allow only requests from this API Gateway
  source_arn = "${aws_apigatewayv2_api.swp-api.execution_arn}/*/*"
}
