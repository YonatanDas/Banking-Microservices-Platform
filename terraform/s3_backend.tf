terraform {
  backend "s3" {
    bucket         = "banking-terraform-state-18.10.25"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
