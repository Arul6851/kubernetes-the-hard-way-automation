# ----------------------------------------------------------------------------
# Kubernetes The Hard Way – Unit 1 (Prereqs) – Terraform on AWS
# Provisions 4 Debian 12 (bookworm) EC2 instances: jumpbox, server, node-0, node-1
# Uses the exact specs defined in the tutorial: jumpbox (512MB RAM), server & workers (2GB RAM).
# ----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

# ------------------------
# Variables
# ------------------------
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the existing AWS EC2 key pair to use"
  type        = string
  default     = "lin-pwd-virginia"
}

variable "ssh_ingress_cidr" {
  description = "CIDR block allowed to SSH into instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_zone" {
  description = "Availability Zone for subnet placement"
  type        = string
  default     = "us-east-1a"
}

variable "ansible_ssh_user" {
  description = "SSH user for Debian AMI"
  type        = string
  default     = "admin"
}

# ------------------------
# Networking
# ------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "kthw-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "kthw-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.42.0.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "kthw-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "kthw-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "ssh" {
  name        = "kthw-ssh"
  description = "Allow SSH + intra-cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "intra-sg"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kthw-ssh"
  }
}

# ------------------------
# Instances
# ------------------------
locals {
  common_tags = {
    Project = "kubernetes-the-hard-way"
    Unit    = "01-prereqs"
  }

  cloud_init = <<-EOT
    #cloud-config
    preserve_hostname: false
    runcmd:
      - echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf
      - sysctl -p
      - bash -lc 'cat /etc/os-release'
  EOT
}

# Jumpbox: 1 vCPU, 512MB RAM, 10GB storage
resource "aws_instance" "jumpbox" {
  ami                         = "ami-0779caf41f9ba54f0"
  instance_type               = "t3.nano" # 0.5GB RAM
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.cloud_init

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "jumpbox" })
}

# Server: 1 vCPU, 2GB RAM, 20GB storage
resource "aws_instance" "server" {
  ami                         = "ami-0779caf41f9ba54f0"
  instance_type               = "t3.small" # 2GB RAM
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.cloud_init

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "server" })
}

# Worker nodes: 1 vCPU, 2GB RAM, 20GB storage each
resource "aws_instance" "node_0" {
  ami                         = "ami-0779caf41f9ba54f0"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.cloud_init

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "node-0" })
}

resource "aws_instance" "node_1" {
  ami                         = "ami-0779caf41f9ba54f0"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.cloud_init

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = merge(local.common_tags, { Name = "node-1" })
}

# ------------------------
# Ansible inventory file
# ------------------------
locals {
  inventory = <<-EOT
  [jumpbox]
  jumpbox ansible_host=${aws_instance.jumpbox.public_ip} ansible_user=${var.ansible_ssh_user}

  [control]
  server ansible_host=${aws_instance.server.public_ip} ansible_user=${var.ansible_ssh_user}

  [workers]
  node-0 ansible_host=${aws_instance.node_0.public_ip} ansible_user=${var.ansible_ssh_user}
  node-1 ansible_host=${aws_instance.node_1.public_ip} ansible_user=${var.ansible_ssh_user}

  [all:vars]
  ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
}

resource "local_file" "ansible_inventory" {
  filename = "ansible-inventory.ini"
  content = trim(local.inventory, " \n\r\t")

}

# ------------------------
# Outputs
# ------------------------
output "public_ips" {
  description = "Public IPs of all nodes"
  value = {
    jumpbox = aws_instance.jumpbox.public_ip
    server  = aws_instance.server.public_ip
    node_0  = aws_instance.node_0.public_ip
    node_1  = aws_instance.node_1.public_ip
  }
}

output "ssh_examples" {
  description = "Convenient SSH commands"
  value = <<-EOT
  ssh -i ~/.ssh/${var.key_name}.pem ${var.ansible_ssh_user}@${aws_instance.jumpbox.public_ip}
  ssh -i ~/.ssh/${var.key_name}.pem ${var.ansible_ssh_user}@${aws_instance.server.public_ip}
  ssh -i ~/.ssh/${var.key_name}.pem ${var.ansible_ssh_user}@${aws_instance.node_0.public_ip}
  ssh -i ~/.ssh/${var.key_name}.pem ${var.ansible_ssh_user}@${aws_instance.node_1.public_ip}
  EOT
}

output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}
