resource "aws_s3_bucket" "terraform-state-remote-back-end" {
  bucket = "terraform-state-remote-back-end"
  
  tags = {
    Name = "Cloud Resume Infrastructure"
  }
}

resource "aws_s3_bucket_versioning" "terraform-state-remote-back-end-versioning" {
  bucket = aws_s3_bucket.terraform-state-remote-back-end.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block_all_public_access_means" {
  bucket = aws_s3_bucket.terraform-state-remote-back-end.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
