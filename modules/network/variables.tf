variable "vpc_cidr" {
  type = string
  default = "10.240.0.0/16"
}

variable "subnet_cidr" {
  type = string
  default = "10.240.0.0/24"
}

variable "availability_zone" {
  type = string
  default = "us-east-1a"
}
