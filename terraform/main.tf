
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
    suffix = "index.html"
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

# To updload all files present in the "html" folder to my new S3 bucket
resource "aws_s3_object" "upload_object" {
  for_each      = fileset("html/", "*")
  bucket        = aws_s3_bucket.my_bucket.id
  key           = each.value
  source        = "html/${each.value}"
  etag          = filemd5("html/${each.value}")
  content_type  = "text/html"
}
