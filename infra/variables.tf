variable "project_name" {
  type        = string
  description = "Short prefix applied to every resource name"
  default     = "swp"
}

variable "aws_region" {
  type        = string
  description = "AWS region for all regional resources"
  default     = "ap-south-1"
}

variable "alert_email" {
  type        = string
  description = "Email address that receives CloudWatch alarm notifications"
  default     = "nihalrejeti@gmail.com"
}

variable "image_tag" {
  type        = string
  description = "ECR image tag the Lambda runs. CI passes the commit SHA."
  default     = "bootstrap"
}
