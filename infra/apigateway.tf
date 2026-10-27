# HTTP API (cheaper and simpler than a REST API) with one route: GET /count.
resource "aws_apigatewayv2_api" "swp_api" {
  name          = "swp-http-api"
  protocol_type = "HTTP"

  # API Gateway answers CORS preflight requests itself, so the browser can
  # call this API from the CloudFront domain.
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
  }
}

# Proxy integration: the whole request is passed to Lambda as an event.
resource "aws_apigatewayv2_integration" "swp_lambda" {
  api_id                 = aws_apigatewayv2_api.swp_api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.swp_counter.invoke_arn
}

resource "aws_apigatewayv2_route" "get_count" {
  api_id    = aws_apigatewayv2_api.swp_api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.swp_lambda.id}"
}

# "$default" stage with auto-deploy: changes go live without a manual deployment.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.swp_api.id
  name        = "$default"
  auto_deploy = true
}

# Lets API Gateway invoke the function. source_arn limits this to this one API.
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.swp_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.swp_api.execution_arn}/*/*"
}

# Resource names were renamed from hyphens to underscores (Terraform convention).
# These blocks tell Terraform the old and new names are the same resources, so
# nothing is destroyed or recreated.
moved {
  from = aws_apigatewayv2_api.swp-api
  to   = aws_apigatewayv2_api.swp_api
}

moved {
  from = aws_apigatewayv2_integration.swp-api
  to   = aws_apigatewayv2_integration.swp_lambda
}

moved {
  from = aws_apigatewayv2_route.swp-api-route
  to   = aws_apigatewayv2_route.get_count
}

moved {
  from = aws_apigatewayv2_stage.swp-api-stage
  to   = aws_apigatewayv2_stage.default
}

moved {
  from = aws_lambda_permission.swp-api-permission
  to   = aws_lambda_permission.allow_api_gateway
}
