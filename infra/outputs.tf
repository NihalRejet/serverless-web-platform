output "bucket_name" {
  description = "Name of the S3 bucket holding the site content"
  value       = aws_s3_bucket.site_bucket.id
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket holding CloudFront access logs"
  value       = aws_s3_bucket.logs.id
}

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.site_distribution.id
}

output "site_url" {
  description = "The full HTTPS URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.site_distribution.domain_name}"
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.swp_counter_ecr.repository_url
}

output "lambda_url" {
  description = "The public URL of the Lambda function"
  value       = aws_lambda_function_url.swp_counter_url.function_url
}

output "api_endpoint" {
  description = "The HTTP API URL"
  value       = aws_apigatewayv2_api.swp-api.api_endpoint
}
