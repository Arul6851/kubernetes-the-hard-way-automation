data "aws_ami" "debian12" {
  most_recent = true
  owners      = ["136693071363"] # Debian official

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
}

# Instance definitions
locals {
  instances = {
    jumpbox = { type = "t3.micro",   disk = 10,  role = "admin" }
    server  = { type = "t3.small",   disk = 20,  role = "server" }
    node-0  = { type = "t3.small",   disk = 20,  role = "worker" }
    node-1  = { type = "t3.small",   disk = 20,  role = "worker" }
  }
}

resource "aws_instance" "this" {
  for_each          = local.instances
  ami               = data.aws_ami.debian12.id
  instance_type     = each.value.type
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name          = var.key_name
  availability_zone = var.availability_zone

  root_block_device {
    volume_size = each.value.disk
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
    Role = each.value.role
  }
}
