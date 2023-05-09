output "web_instance_ip" {
    value = aws_instance.web.public_ip
}

output "instance_id" {
    value = aws_instance.web.id
}

output "private_key" {
    value = tls_private_key.key_type.private_key_pem
    sensitive = true
}
