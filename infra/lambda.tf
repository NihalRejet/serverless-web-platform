# 1. The IAM Role (The ID Badge)
resource "aws_iam_role" "swp_lambda_role" {
  name = "swp_lambda_role"

  # This JSON tells AWS that the Lambda service is allowed to wear this badge
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  # The inline policy granting DynamoDB access
  inline_policy {
    name = "dynamodb_update_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "dynamodb:UpdateItem"
          Effect = "Allow"
          # This points exactly to your table from Stage 4
          Resource = aws_dynamodb_table.swp-visitor-counter-table.arn
        }
      ]
    })
  }
}

# 2. Attach the AWS-managed policy for writing CloudWatch logs
resource "aws_iam_role_policy_attachment" "swp_lambda_logs_attachment" {
  role       = aws_iam_role.swp_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. The Lambda Function itself
resource "aws_lambda_function" "swp_counter" {
  function_name = "swp-counter"

  # Connects the Lambda to the IAM role above
  role = aws_iam_role.swp_lambda_role.arn

  package_type = "Image"

  # Points to the bootstrap image you pushed in Task 5.4
  image_uri = "${aws_ecr_repository.swp_counter_ecr.repository_url}:bootstrap"

  # Passes the table name to your app.py script
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.swp-visitor-counter-table.name
    }
  }
}

resource "aws_lambda_function_url" "swp_counter_url" {
  function_name = aws_lambda_function.swp_counter.function_name

  # "NONE" means anyone on the internet can hit this URL without needing AWS credentials
  authorization_type = "NONE"

  cors {
    # Allows any website to make a request to this URL
    allow_origins = ["*"]
    # Allows standard web request methods
    allow_methods = ["GET", "POST"]
  }
}
