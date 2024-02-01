terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = "*********"
  secret_key = "*********"
}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

variable "key_name" {
  description = "Name of SSH key pair"
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = "/home/ubuntu/demo-app/${var.key_name}.pem"  # Specify .pem extension

  provisioner "local-exec" {
    command = "chmod 600 /home/ubuntu/demo-app/${var.key_name}.pem"
  }
}

resource "aws_security_group" "sg_ec2" {
  name        = "sg_ec2"
  description = "Security Group for EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "public_instance" {
  ami                    = "ami-03f4878755434977f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  tags = {
    name = "public_instance"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.public_instance.public_ip},' --user ubuntu --private-key=/home/ubuntu/demo-app/${var.key_name}.pem docker-install.yml"
  }
}
