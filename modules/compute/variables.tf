variable "ami_id" {
  type = string
    default = "ami-0779caf41f9ba54f0"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "key_name" {
  type = string
  default = "lin-pwd-virginia"
}

variable "name" {
  type = string
  default = "k8s-instance"
}
