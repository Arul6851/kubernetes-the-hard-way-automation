output "public_ips" {
  value = module.ec2.public_ips
}

output "private_ips" {
  value = module.ec2.private_ips
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content  = module.ec2.inventory
  filename = "${path.module}/inventory.ini"
}
