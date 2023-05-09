terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "s3-backend-anmute"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "anmutetable"
    encrypt        = true
  }
}
