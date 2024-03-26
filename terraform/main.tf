
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

resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.public_read_access.json
}
