resource "aws_vpc" "vpc_virginia" {
  cidr_block = var.virgina_cidr
  tags = {
    Name = "vpc_virginia"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc_virginia.id
  #cidr_block              = var.public_subnet
  cidr_block              = var.subnets[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc_virginia.id
  #cidr_block = var.private_subnet
  cidr_block = var.subnets[1]
  tags = {
    Name = "private_subnet"
  }
  depends_on = [aws_subnet.public_subnet]
}