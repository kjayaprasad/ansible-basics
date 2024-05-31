terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48"
    }
  }
}

variable "aws_key_pair" {
  default = "//ec2-instance-with-ansible-and-tf//default-ec2.pem"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound SSH traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

data "aws_subnet" "default_subnet" {
  vpc_id            = aws_default_vpc.default.id
  availability_zone = "us-east-1a" // Specify the desired availability zone
}

resource "aws_elb" "elb" {
  name               = "elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  security_groups    = [aws_security_group.elb_sg.id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
}

resource "aws_instance" "http_servers" {
  count                  = 3
  ami                    = "ami-00beae93a2d981137" # Update with correct AMI ID
  key_name               = "default-ec2"           # Ensure this matches your created key pair
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.elb_sg.id]
  subnet_id              = data.aws_subnet.default_subnet.id # Reference the subnet ID

  tags = {
    Name = "http_server_${count.index + 1}"
  }
}






