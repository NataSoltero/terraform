resource "aws_s3_bucket" "proveedores" {
  count  = 6
  bucket = "soltero-test-bucket-${random_string.sufijo[count.index].id}"

  tags = {
    Name = "Soltero Bucket"
  }
}

resource "random_string" "sufijo" {
  count   = 6
  length  = 8
  special = false
  upper   = false
  numeric = false
}