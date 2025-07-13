# Provider
terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
        }
    }
}

provider "aws" {
  region = "us-east-1"
}

# VPC And Subnet
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "Main VPC"
    }
}

# Subnets
resource "aws_subnet" "my_subent" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.my_subnet
    availability_zone = "us-east-1a"

    tags = {
        Name = "my_subent"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "igw"
    }   
}

# Route Tables
resource "aws_route_table" "my_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "my_rt"
    }
}

# Route Tables Association
resource "aws_route_table_association" "my_association" {
    subnet_id = aws_subnet.my_subent.id
    route_table_id = aws_route_table.my_rt.id
}

# AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] 
}

# Secuirty Group
resource "aws_security_group" "my_sg" {
    vpc_id = aws_vpc.main.id
    name = "my_sg"

    tags = {
        Name = "my_sg"
    }

}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.my_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_vpc" {
    security_group_id = aws_security_group.my_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 27017
    to_port = 27017
    ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_outband" {
    security_group_id = aws_security_group.my_sg.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

# S3
resource "aws_s3_bucket" "my_bucket_44" {
    bucket = "db-buckup-44"

    tags = {
        Name = "db_buckup"
    }
}

resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
    bucket = aws_s3_bucket.my_bucket_44.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "my_lc" {
    bucket = aws_s3_bucket.my_bucket_44.id

    rule {
        id     = "Move old versions to Glacier"
        status = "Enabled"

        filter {} 

        noncurrent_version_transition {
        noncurrent_days = 7
        storage_class   = "GLACIER"
        }
    }
}

# IAM 
resource "aws_iam_role" "ec2_s3" {
  name = "ec2-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "s3-access-for-ec2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = [
          aws_s3_bucket.my_bucket_44.arn,
          "${aws_s3_bucket.my_bucket_44.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_policy" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_s3.name
}

# Key
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("/home/zakaria/Desktop/.ssh/tmp/web_server_key.pub")
}

# EC2 Instance
resource "aws_instance" "db_host" {
    ami = data.aws_ami.amazon_linux.id
    subnet_id = aws_subnet.my_subent.id
    instance_type = "t2.micro"
    user_data = file("../scripts/startup.sh")
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    key_name = aws_key_pair.ssh_key.key_name
    associate_public_ip_address = true

    tags = {
        Name = "db_host"
    }
}

