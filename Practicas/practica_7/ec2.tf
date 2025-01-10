resource "aws_instance" "public_instance" {
  ami           = "ami-0453ec754f44f9a4a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
}