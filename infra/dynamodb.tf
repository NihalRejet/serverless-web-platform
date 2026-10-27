# One item ({ id = "visits" }) holds the counter. On-demand billing costs
# nothing when idle.
resource "aws_dynamodb_table" "visitor_counter" {
  name         = "swp-visitor-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Continuous backups: the table can be restored to any second in the last 35 days.
  point_in_time_recovery {
    enabled = true
  }
}

# Renamed from a hyphenated name. Keeps the existing table (no destroy).
moved {
  from = aws_dynamodb_table.swp-visitor-counter-table
  to   = aws_dynamodb_table.visitor_counter
}
