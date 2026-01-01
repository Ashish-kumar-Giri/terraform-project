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



/*resource "aws_s3_bucket" "demo" {
  bucket = "${var.bucket_item}-${random_integer.rand.result}"
}

/*resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  
user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1
sudo systemctl start nginx
sudo systemctl enable nginx
EOF


  tags = {
    Name = "terraform-ec2-basic-changes have been made"
  }

}*/

resource "aws_launch_template" "web_lt" {
  name_prefix   = "nginx-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  vpc_security_group_ids = [
    aws_security_group.allow_ssh_http.id
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install nginx1
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "asg-nginx-instance"
    }
  }
}

resource "aws_launch_template" "green_lt" {
  name_prefix   = "green-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  key_name      = aws_key_pair.terraform_key.key_name

  vpc_security_group_ids = [
    aws_security_group.allow_ssh_http.id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash
yum install -y nginx
echo "<h1>GREEN VERSION</h1>" > /usr/share/nginx/html/index.html
systemctl start nginx
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "green-nginx-instance"
    }
  }
}


resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]   

  }
  tags = {
    "Name" = "terraform-allow_ssh_http"
  } 
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = file(var.public_key_path)
}

/*resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-nginx"
    propagate_at_launch = true
    
  }

  tag {
    key                 = "Name"
    value               = "asg-nginx-ashish"
    propagate_at_launch = true
  }
}*/
data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-http-sg"
  description = "Allow HTTP traffic to ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ashish-alb-http-sg"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id  = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "green_tg" {
  name     = "nginx-green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}


resource "aws_lb" "web_alb" {
  name               = "nginx-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "nginx-alb"
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green_tg.arn
  }
}
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 3
  max_size         = 4
  min_size         = 1

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

instance_refresh {
  strategy = "Rolling"

  triggers = ["launch_template"]

  preferences {
    min_healthy_percentage = 50
    instance_warmup        = 60
  }
}


  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-nginx-1"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_group" "green_asg" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns  = [aws_lb_target_group.green_tg.arn]

  launch_template {
    id      = aws_launch_template.green_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-green-nginx"
    propagate_at_launch = true
  }
}


