terraform {
backend "s3" {
bucket = "sujal-terraform-state"
key = "network/vpc/terraform.tfstate"
region = "us-east-1"
use_lockfile = true
encrypt = true
}
}