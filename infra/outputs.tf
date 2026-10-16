output "bucket_name" {
  description = "Name of the S3 bucket used to store site content"
  value       = aws_s3_bucket.site-bucket.id
}

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.site_distribution.id
}

output "site_url" {
  description = "The full HTTPS URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.site_distribution.domain_name}"
}
