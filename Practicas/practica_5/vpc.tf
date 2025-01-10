resource "aws_vpc" "vpc_virginia" {
  cidr_block = var.virgina_cidr
  tags = {
    Name = "VPC_VIRGINIA"
    env  = "dev"
  }
}

resource "aws_vpc" "vpc_ohio" {
  cidr_block = var.ohio_cidr
  tags = {
    Name = "VPC_OHIO"
    env  = "dev"
  }
  provider = aws.ohio
}
