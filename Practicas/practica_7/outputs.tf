output "ec2_public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.public_instance.public_ip
}