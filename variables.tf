variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "lin-pwd-virginia"
}

variable "project_name" {
  default = "k8s-hard-way"
}

variable "ami_id" {
  description = "AMI ID for the instances"
  type        = string
  default     = "ami-0779caf41f9ba54f0"
}