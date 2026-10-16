variable "project_name" {
  type    = string
  default = "swp"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "alert_email" {
  type        = string
  description = "Email address for CloudWatch alarms"
}

variable "image_tag" {
  type    = string
  default = "bootstrap"
}
