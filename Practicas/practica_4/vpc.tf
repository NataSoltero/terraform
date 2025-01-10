resource "aws_vpc" "vpc_virginia" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "VPC_VIRGINIA"
    env  = "dev"
  }
}

resource "aws_vpc" "vpc_ohio" {
  cidr_block = "10.10.0.0/16"
  tags = {
    Name = "VPC_OHIO"
    env  = "dev"
  }
  provider = aws.ohio
}