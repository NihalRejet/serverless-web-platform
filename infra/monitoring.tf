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
