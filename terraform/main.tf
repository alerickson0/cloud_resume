
resource "random_string" "bucket_name_add" {
  length           = 16
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

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.public_read_access.json
}
