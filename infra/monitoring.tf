# Accepted: the topic is not encrypted. CloudWatch alarms cannot publish to a topic
# encrypted with the default AWS-managed key (alias/aws/sns), and a customer-managed
# KMS key costs money. The messages only contain alarm names, no sensitive data.
#trivy:ignore:AWS-0095
resource "aws_sns_topic" "swp_alerts" {
  name = "swp-alerts"
}

# Email subscriptions must be confirmed from the email AWS sends; until then
# nothing is delivered, even though Terraform reports success.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.swp_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Fires when the function fails (unhandled error or timeout) and emails the
# topic. ok_actions sends a second email when it recovers.
resource "aws_cloudwatch_metric_alarm" "swp_lambda_errors" {
  alarm_name          = "swp-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "swp-counter had 1 or more errors in a 1-minute window"
  alarm_actions       = [aws_sns_topic.swp_alerts.arn]
  dimensions = {
    FunctionName = aws_lambda_function.swp_counter.function_name
  }
  treat_missing_data = "notBreaching"
  ok_actions         = [aws_sns_topic.swp_alerts.arn]
}

# Lambda's log group. Without this, Lambda creates it with no expiry and logs
# are kept forever. (It was adopted into Terraform once with an import block.)
resource "aws_cloudwatch_log_group" "swp_counter" {
  name              = "/aws/lambda/${aws_lambda_function.swp_counter.function_name}"
  retention_in_days = 14
}
