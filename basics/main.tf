terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-west-1"
  
}
resource "random_integer" "rand" {
    min = 1000
    max = 9998
}

resource "aws_s3_bucket" "demo" {
  bucket = "${var.bucket_item}-${random_integer.rand.result}"
}