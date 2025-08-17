resource "aws_s3_bucket" "vw_challenge_bucket" {
  bucket = "vwchallengebucket"

  tags = merge(
    var.tags
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.vw_challenge_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # SSE-S3 encryption
    }
  }
}