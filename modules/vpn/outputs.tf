output "vpn_endpoint_dns_name" {
  description = "The ID of the VPC"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}
