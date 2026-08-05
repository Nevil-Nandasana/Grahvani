# AWS S3 Buckets for Grahvani
# Private buckets for curated astrological sources, PDF exports, and user uploads.

# Private bucket for curated classical texts (PDFs, Sanskrit shlokas)
resource "aws_s3_bucket" "curated_sources" {
  bucket = "${var.aws_s3_bucket_prefix}-curated-sources"
  force_destroy = false  # Prevent accidental deletion
  
  tags = {
    Name        = "grahvani-curated-sources"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# Enable versioning for curated sources
resource "aws_s3_bucket_versioning" "curated_sources" {
  bucket = aws_s3_bucket.curated_sources.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for curated sources
resource "aws_s3_bucket_server_side_encryption_configuration" "curated_sources" {
  bucket = aws_s3_bucket.curated_sources.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for curated sources
resource "aws_s3_bucket_public_access_block" "curated_sources" {
  bucket = aws_s3_bucket.curated_sources.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Private bucket for generated PDF birth charts
resource "aws_s3_bucket" "pdf_exports" {
  bucket = "${var.aws_s3_bucket_prefix}-pdf-exports"
  force_destroy = false
  
  tags = {
    Name        = "grahvani-pdf-exports"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# Enable versioning for PDF exports
resource "aws_s3_bucket_versioning" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for PDF exports
resource "aws_s3_bucket_server_side_encryption_configuration" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for PDF exports
resource "aws_s3_bucket_public_access_block" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Policy for App Runner to access S3
resource "aws_iam_policy" "s3_access" {
  name        = "grahvani-s3-access-policy"
  description = "Policy for Grahvani App Runner to access S3 buckets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
        ],
        Resource = [
          aws_s3_bucket.curated_sources.arn,
          "${aws_s3_bucket.curated_sources.arn}/*",
          aws_s3_bucket.pdf_exports.arn,
          "${aws_s3_bucket.pdf_exports.arn}/*",
        ]
      }
    ]
  })
}

# Attach S3 policy to App Runner role
resource "aws_iam_role_policy_attachment" "apprunner_s3_access" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# S3 Bucket Notification for PDF processing (trigger Dramatiq worker)
resource "aws_s3_bucket_notification" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id
  
  topic {
    topic_arn     = aws_sns_topic.pdf_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".pdf"
  }
}

# SNS Topic for PDF processing
resource "aws_sns_topic" "pdf_processing" {
  name = "grahvani-pdf-processing"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = "arn:aws:sns:*:*:grahvani-pdf-processing"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.pdf_exports.arn
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "grahvani-pdf-processing"
  }
}