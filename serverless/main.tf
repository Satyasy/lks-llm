provider "aws" {
  region = "us-east-1"
}

#########################
# VPC DAN SUBNET
#########################

resource "aws_vpc" "techno_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "techno-vpc"
  }
}

resource "aws_internet_gateway" "techno_igw" {
  vpc_id = aws_vpc.techno_vpc.id
  tags = {
    Name = "techno-igw"
  }
}

resource "aws_subnet" "techno_public_a" {
  vpc_id                  = aws_vpc.techno_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "techno-public-subnet-a"
  }
}

resource "aws_subnet" "techno_public_b" {
  vpc_id                  = aws_vpc.techno_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "techno-public-subnet-b"
  }
}

resource "aws_subnet" "techno_private_a" {
  vpc_id            = aws_vpc.techno_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "techno-private-subnet-a"
  }
}

resource "aws_subnet" "techno_private_b" {
  vpc_id            = aws_vpc.techno_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "techno-private-subnet-b"
  }
}

resource "aws_eip" "techno_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "techno_nat" {
  allocation_id = aws_eip.techno_nat_eip.id
  subnet_id     = aws_subnet.techno_public_a.id
  tags = {
    Name = "techno-nat"
  }
}

resource "aws_route_table" "techno_public_rt" {
  vpc_id = aws_vpc.techno_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techno_igw.id
  }
}

resource "aws_route_table_association" "techno_public_assoc_a" {
  subnet_id      = aws_subnet.techno_public_a.id
  route_table_id = aws_route_table.techno_public_rt.id
}

resource "aws_route_table_association" "techno_public_assoc_b" {
  subnet_id      = aws_subnet.techno_public_b.id
  route_table_id = aws_route_table.techno_public_rt.id
}

resource "aws_route_table" "techno_private_rt" {
  vpc_id = aws_vpc.techno_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.techno_nat.id
  }
}

resource "aws_route_table_association" "techno_private_assoc_a" {
  subnet_id      = aws_subnet.techno_private_a.id
  route_table_id = aws_route_table.techno_private_rt.id
}

resource "aws_route_table_association" "techno_private_assoc_b" {
  subnet_id      = aws_subnet.techno_private_b.id
  route_table_id = aws_route_table.techno_private_rt.id
}

#########################
# SECURITY GROUPS
#########################

resource "aws_security_group" "techno_sg_app" {
  name   = "techno-sg-app"
  vpc_id = aws_vpc.techno_vpc.id

  ingress {
    from_port   = 2000
    to_port     = 2000
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
    Name = "techno-sg-app"
  }
}

resource "aws_security_group" "techno_sg_alb" {
  name   = "techno-sg-alb"
  vpc_id = aws_vpc.techno_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "techno-sg-alb"
  }
}

#########################
# S3, DYNAMODB, KINESIS
#########################

resource "aws_s3_bucket" "techno_data_bucket" {
  bucket = "techno-data-bucket"
  tags = {
    Name = "techno-data-bucket"
  }
}

resource "aws_dynamodb_table" "techno_config_table" {
  name         = "techno-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "techno-config"
  }
}

resource "aws_kinesis_stream" "techno_stream" {
  name        = "techno-stream"
  shard_count = 1
  tags = {
    Name = "techno-stream"
  }
}

#########################
# AWS GLUE
#########################

resource "aws_glue_catalog_database" "techno_glue_db" {
  name = "techno_glue_db"
}

resource "aws_glue_crawler" "techno_crawler" {
  name          = "techno-crawler"
  role          = "arn:aws:iam::123456789012:role/AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.techno_glue_db.name

  targets {
    s3_targets {
      path = "s3://${aws_s3_bucket.techno_data_bucket.bucket}/input-data"
    }
  }
}

#########################
# API GATEWAY & SNS
#########################

resource "aws_api_gateway_rest_api" "techno_api" {
  name        = "techno-api"
  description = "API Gateway for techno project"
}

resource "aws_sns_topic" "techno_alerts" {
  name = "techno-alerts"
}