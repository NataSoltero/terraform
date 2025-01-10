variable "virgina_cidr" {
  description = "CIDR Virginia"
  type        = string
}

#variable "public_subnet" {
#description = "CIDR public subnet"
#type        = string
#}
#
#variable "private_subnet" {
#description = "CIDR private subnet"
#type        = string
#}

variable "subnets" {
  description = "Subnets list"
  type        = list(string)
}

variable "tags" {
  description = "Tags del proyecto"
  type        = map(string)
}