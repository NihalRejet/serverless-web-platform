# Safety net for the free-tier account: emails when actual spend passes 80% of
# $5 in a month. No cost filter, so it covers every service.
resource "aws_budgets_budget" "swp_monthly_cap_budget" {
  name         = "swp-monthly-cap"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
