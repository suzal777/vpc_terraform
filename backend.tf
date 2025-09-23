# Uncomment and configure if you want remote backend
# terraform {
# backend "s3" {
# bucket = "my-terraform-state-bucket"
# key = "network/vpc/terraform.tfstate"
# region = "us-east-1"
# dynamodb_table = "terraform-locks"
# encrypt = true
# }
# }