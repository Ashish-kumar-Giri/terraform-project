variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair to use/create"
  type        = string
  default     = "tf-demo-key"
}

variable "public_key_path" {
  description = "Absolute path to your local public SSH key (e.g. /Users/ashish/.ssh/id_rsa.pub). We'll pass it at runtime."
  type        = string
  default     = ""
}

