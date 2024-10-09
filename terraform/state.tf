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
