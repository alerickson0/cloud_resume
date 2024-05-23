locals {
  s3_origin_id = "resumeS3Origin"
}

resource "random_string" "bucket_name_add" {
  length           = 16
  upper            = false
  special          = true
  override_special = ".-"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "cloud-resume-${random_string.bucket_name_add.result}"

  # Do I need tags?
  tags = {
    Name = "Cloud Resume Bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "test_site" {
  bucket = aws_s3_bucket.my_bucket.id
  index_document {
    suffix = "Alvaro_E_resume.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.public_read_access.json
}

# To upload all files present in the "resume" folder to my new S3 bucket
resource "aws_s3_object" "upload_object" {
  for_each      = fileset("resume/", "**")
  bucket        = aws_s3_bucket.my_bucket.id
  key           = each.value
  source        = "resume/${each.value}"
  etag          = filemd5("resume/${each.value}")
  content_type  = "text/html"
}

resource "aws_cloudfront_response_headers_policy" "my-custom-javascript-response" {
  name = "custom-javascript-response"

  custom_headers_config {
    items {
      header   = "Content-Type"
      override = true
      value    = "text/javascript"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "my-custom-css-response" {
  name = "custom-css-response"

  custom_headers_config {
    items {
      header   = "Content-Type"
      override = true
      value    = "text/css"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "my_headers_policy" {
  name = "security-headers-policy"
  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      override     = true
      frame_option = "DENY"
    }

    referrer_policy {
      override        = true
      referrer_policy = "same-origin"
    }

    strict_transport_security {
      override                   = true
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
    }

    xss_protection {
      override   = true
      mode_block = true
      protection = true
    }
  }
}

# To updload all files present in the "resume" folder to my new S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront for my resume site"
  default_root_object = "Alvaro_E_resume.html"

  aliases = [var.site_name, "www.${var.site_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy     = "allow-all"
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
    response_headers_policy_id = aws_cloudfront_response_headers_policy.my_headers_policy.id
  }

    # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                    = 0
    default_ttl                = 86400
    max_ttl                    = 31536000
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.my_headers_policy.id
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.my_headers_policy.id
  }

  # Cache behavior with precedence 2. For JavaScript handling
  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Using recommended for S3, Managed-CachingOptimized

    min_ttl                    = 0
    default_ttl                = 86400
    max_ttl                    = 31536000
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.my-custom-javascript-response.id
  }

  # Cache behavior with precedence 3. For css handling
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Using recommended for S3, Managed-CachingOptimized

    min_ttl                    = 0
    default_ttl                = 86400
    max_ttl                    = 31536000
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.my-custom-css-response.id
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.ssl_certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
    #cloudfront_default_certificate = true -- Use for testing just CloudFront, but comment out above parameters
  }

}
