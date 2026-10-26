resource "random_id" "suffix" {
  byte_length = 4
}

# ---------------------------------------------------------------------------
# Site bucket - private. Only CloudFront may read from it.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "site_bucket" {
  bucket = "${var.project_name}-site-${random_id.suffix.hex}"

  # Demo project: lets `terraform destroy` remove the bucket without emptying
  # it by hand first. Would not be set on anything holding real data.
  force_destroy = true

  tags = {
    Name = "${var.project_name}-site"
  }
}

resource "aws_s3_bucket_public_access_block" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 applies SSE-S3 to new buckets by default. Declaring it keeps the setting
# visible in code and stops IaC scanners flagging an implicit default.
# Accepted (Trivy AWS-0132): a customer-managed KMS key adds monthly cost and
# key-policy work for OAC. The bucket is still encrypted with AWS-managed keys.
#trivy:ignore:AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning gives a rollback path if a bad deploy overwrites the site.
resource "aws_s3_bucket_versioning" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Every deploy writes new versions, so expire the old ones rather than paying
# to store every build forever.
resource "aws_s3_bucket_lifecycle_configuration" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.site_bucket]
}

# ---------------------------------------------------------------------------
# CloudFront access logs
#
# The site bucket itself has no S3 server access logging. CloudFront is the
# only reader, so these distribution logs already record every request that
# reaches the origin. A second log trail would duplicate them at extra cost.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project_name}-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Accepted (Trivy AWS-0132): SSE-KMS is not supported for log delivery
# destination buckets, so SSE-S3 (AES256) is the correct choice here.
#trivy:ignore:AWS-0132
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront standard logging delivers objects using an ACL, so this bucket
# cannot use the modern BucketOwnerEnforced default. It is the one place in
# this project where ACLs stay enabled.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# ---------------------------------------------------------------------------
# CloudFront
# ---------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "site_oac" {
  name                              = "${var.project_name}-site-oac"
  description                       = "Lets CloudFront sign its requests to the private site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.project_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

# Accepted (Trivy AWS-0011): a WAF is billed monthly and is outside the free
# tier. Mitigated by a private bucket (OAC only) and a security headers policy.
#trivy:ignore:AWS-0011
resource "aws_cloudfront_distribution" "site_distribution" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project_name} static site"

  origin {
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.site_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.site_oac.id
  }

  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.site_bucket.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS managed CachingOptimized policy
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Using the free *.cloudfront.net certificate. minimum_protocol_version
  # cannot be raised here - AWS pins it for the default certificate. Setting
  # TLS 1.2 as a floor would require a custom domain plus an ACM certificate.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # The log bucket must accept ACL-based delivery before CloudFront will
  # accept it as a logging target.
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# ---------------------------------------------------------------------------
# Bucket policy - the only principal allowed to read is this distribution
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid = "AllowCloudFrontRead"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.site_bucket.arn}/*",
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

resource "aws_s3_bucket_policy" "site_bucket" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.site_bucket.json
}
