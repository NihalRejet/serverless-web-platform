# Immutable tags: an image tag (the commit SHA) can never be overwritten.
resource "aws_ecr_repository" "swp_counter_ecr" {
  name                 = "swp-counter"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep only the last 5 images so storage stays inside the free tier.
resource "aws_ecr_lifecycle_policy" "swp_counter_ecr_lifecycle" {
  repository = aws_ecr_repository.swp_counter_ecr.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
