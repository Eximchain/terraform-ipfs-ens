output "api_dns" {
  value = aws_api_gateway_domain_name.domain.domain_name
}

output "deployment_website_dns" {
  value = local.deployment_website_dns
}

