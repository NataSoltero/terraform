resource "random_string" "sufijo" {
  count   = 5
  length  = 4
  special = false
  upper   = false
  numeric = false
}
