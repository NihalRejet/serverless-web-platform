# Execution role for the Lambda. Only the Lambda service can assume it.
resource "aws_iam_role" "swp_lambda_role" {
  name = "swp_lambda_role"

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
}

# Least privilege: the function may only update items in its own table.
# A separate aws_iam_role_policy replaces the deprecated inline_policy block.
resource "aws_iam_role_policy" "dynamodb_update" {
  name = "dynamodb_update_policy"
  role = aws_iam_role.swp_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dynamodb:UpdateItem"
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}

# AWS-managed policy that lets the function write its CloudWatch logs.
resource "aws_iam_role_policy_attachment" "swp_lambda_logs_attachment" {
  role       = aws_iam_role.swp_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "swp_counter" {
  function_name = "swp-counter"
  role          = aws_iam_role.swp_lambda_role.arn
  package_type  = "Image"

  # The pipeline passes the commit SHA, so each deploy runs the image built
  # from that commit. The "bootstrap" default is only for the first setup.
  image_uri = "${aws_ecr_repository.swp_counter_ecr.repository_url}:${var.image_tag}"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }
}
