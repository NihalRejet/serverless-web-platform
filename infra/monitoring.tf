# Accepted: the topic is not encrypted. CloudWatch alarms cannot publish to a topic
# encrypted with the default AWS-managed key (alias/aws/sns), and a customer-managed
# KMS key costs money. The messages only contain alarm names, no sensitive data.
#trivy:ignore:AWS-0095
resource "aws_sns_topic" "swp_alerts" {
  name = "swp-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.swp_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "swp_lambda_errors" {
  alarm_name          = "swp-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This metric monitors lambda function errors"
  alarm_actions       = [aws_sns_topic.swp_alerts.arn]
  dimensions = {
    FunctionName = aws_lambda_function.swp_counter.function_name
  }
  treat_missing_data = "notBreaching"
  ok_actions         = [aws_sns_topic.swp_alerts.arn]
}

# The log group already exists (Lambda created it on first run). This block
# tells Terraform to adopt it instead of failing with "already exists".
import {
  to = aws_cloudwatch_log_group.swp_counter
  id = "/aws/lambda/swp-counter"
}

resource "aws_cloudwatch_log_group" "swp_counter" {
  name              = "/aws/lambda/${aws_lambda_function.swp_counter.function_name}"
  retention_in_days = 14
}
