# AWS ECR Repository for Grahvani
# Container registry for FastAPI backend images.

resource "aws_ecr_repository" "grahvani" {
  name                 = "grahvani"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  tags = {
    Name        = "grahvani-ecr"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# ECR Lifecycle Policy (keep last 10 images, expire untagged after 7 days)
resource "aws_ecr_lifecycle_policy" "grahvani" {
  repository = aws_ecr_repository.grahvani.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countNumber   = 7
          countUnit     = "days"
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy (allow App Runner to pull)
resource "aws_ecr_repository_policy" "grahvani" {
  repository = aws_ecr_repository.grahvani.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppRunnerPull"
        Effect = "Allow"
        Principal = {
          Service = "apprunner.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowCodeBuildPush"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/grahvani-codebuild-role"
        }
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
      }
    ]
  })
}