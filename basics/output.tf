/*output "bucket" {
  value = aws_s3_bucket.demo.bucket
}
#output "ec2_instance_id" {
  # value = aws_instance.web.id
  
#}

# output "ec2_public_ip" {
#  value = aws_instance.web.public_ip
#}

output "ec2_details" {
  value = {
    id            = aws_instance.web_lt.id
    instance_type = aws_instance.web_lt.instance_type
    name          = aws_instance.web_lt.tags["Name"]
    tags          = aws_instance.web_lt.tags
  }
}
*/