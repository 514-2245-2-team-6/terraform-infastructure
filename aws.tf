variable "aws_region" {
	type = string
	description = "AWS Region to deploy to"
	default = "us-east-1"
}
provider "aws" {
  region = var.aws_region
}
