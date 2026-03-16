output "fqdn" {
  description = "FQDN of the created Route53 record."
  value       = aws_route53_record.api.fqdn
}
