output "public_ips" {
  value = { for k, inst in aws_instance.this : k => inst.public_ip }
}

output "private_ips" {
  value = { for k, inst in aws_instance.this : k => inst.private_ip }
}

output "inventory" {
  value = <<EOT
[jumpbox]
${aws_instance.this["jumpbox"].public_ip}

[masters]
${aws_instance.this["server"].private_ip}

[workers]
${aws_instance.this["node-0"].private_ip}
${aws_instance.this["node-1"].private_ip}
EOT
}
