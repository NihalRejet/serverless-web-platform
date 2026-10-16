
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "site-bucket" {
  bucket = "swp-site-${random_id.suffix.hex}"

  tags = {
  Name = "site-bucket" }
}

resource "aws_s3_bucket_public_access_block" "site-bucket-public-access" {
  bucket = aws_s3_bucket.site-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "site-bucket-oac" {
  name                              = "site-bucket-oac"
  description                       = "Site Bucket Origin Access Control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "swp-security-headers"

  security_headers_config {
    # HSTS
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    # Content-Type-Options
    content_type_options {
      override = true
    }

    # Frame-Options
    frame_options {
      frame_option = "DENY"
      override     = true
    }

    # Referrer-Policy
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

resource "aws_cloudfront_distribution" "site_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.site-bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.site-bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.site-bucket-oac.id
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.site-bucket.id
    viewer_protocol_policy = "redirect-to-https"

    # AWS Managed CachingOptimized Policy ID
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # Attaching the policy for security headers to the distribution
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "site-bucket-policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.site-bucket.arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site_bucket_policy_attachment" {
  bucket = aws_s3_bucket.site-bucket.id
  policy = data.aws_iam_policy_document.site-bucket-policy.json
}
