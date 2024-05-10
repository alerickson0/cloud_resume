# Which region will AWS use
variable "region" {
  type = string
  default = "us-east-1"
}

variable "site_name" {
  type = string
  description = "The domain or site to use"
}

variable "ttl" {
  type = number
  default = 60
}
