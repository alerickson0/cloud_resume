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
  for_each      = fileset("resume/", "*")
  bucket        = aws_s3_bucket.my_bucket.id
  key           = each.value
  source        = "resume/${each.value}"
  etag          = filemd5("resume/${each.value}")
  content_type  = "text/html"
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

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
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
    cloudfront_default_certificate = true
  }
}
