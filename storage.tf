data "aws_caller_identity" "current" {}

locals {
  media_bucket_name = lower(coalesce(var.media_bucket_name, "${var.project_name}-${data.aws_caller_identity.current.account_id}-media"))
  media_base_url    = "https://${local.media_bucket_name}.s3.${var.aws_region}.amazonaws.com"
}

resource "aws_s3_bucket" "media" {
  bucket        = local.media_bucket_name
  force_destroy = var.media_bucket_force_destroy

  tags = {
    Name      = "${var.project_name}-media"
    Terraform = "true"
    Project   = var.project_name
    Role      = "media"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "media_public_read" {
  statement {
    sid    = "PublicReadUploadedImages"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.media.arn}/posts/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "media_public_read" {
  bucket = aws_s3_bucket.media.id
  policy = data.aws_iam_policy_document.media_public_read.json

  depends_on = [aws_s3_bucket_public_access_block.media]
}