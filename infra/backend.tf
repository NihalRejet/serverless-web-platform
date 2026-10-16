terraform {
  backend "s3" {
    bucket       = "swp-tfstate-2c9b6692"
    key          = "serverless-web-platform/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
