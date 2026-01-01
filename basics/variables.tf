variable "bucket_item" {
  description = "Prefix for S3 bucket"
  type = string
  default = "ashish-bucket"
}

variable "instance_type" {
  description = "Type of AWS EC2 instance"
  type = string
  default = "t2.micro"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "public_key_path" {
  description = "Path to the public key for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa.pub" 
  
}
data "aws_vpc" "default" {
  default = true
}