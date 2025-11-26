terraform {
  backend "s3" {
    bucket         = "banking-terraform-state-18.10.25"
    key            = "envs/stag/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}