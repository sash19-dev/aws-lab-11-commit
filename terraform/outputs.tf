output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "linux_mgmt_instance_id" {
  value       = var.enable_linux_mgmt_instance ? aws_instance.linux_mgmt[0].id : null
  description = "Instance ID of temporary Linux management host"
}

output "linux_mgmt_private_ip" {
  value       = var.enable_linux_mgmt_instance ? aws_instance.linux_mgmt[0].private_ip : null
  description = "Private IP of temporary Linux management host"
}

output "linux_mgmt_role_arn" {
  value       = var.enable_linux_mgmt_instance ? aws_iam_role.linux_mgmt[0].arn : null
  description = "IAM role ARN attached to Linux management host"
}

output "windows_mgmt_instance_id" {
  value       = var.enable_windows_mgmt_instance ? aws_instance.windows_mgmt[0].id : null
  description = "Instance ID of private Windows management host"
}

output "windows_mgmt_private_ip" {
  value       = var.enable_windows_mgmt_instance ? aws_instance.windows_mgmt[0].private_ip : null
  description = "Private IP of private Windows management host"
}

output "windows_mgmt_role_arn" {
  value       = var.enable_windows_mgmt_instance ? aws_iam_role.windows_mgmt[0].arn : null
  description = "IAM role ARN attached to Windows management host"
}

output "private_hosted_zone_id" {
  value       = aws_route53_zone.private.zone_id
  description = "Private Route53 hosted zone ID for internal application DNS"
}

output "internal_app_fqdn" {
  value       = local.app_fqdn
  description = "Internal application FQDN managed by Route53/external-dns"
}

output "internal_app_acm_certificate_arn" {
  value       = aws_acm_certificate.app_tls.arn
  description = "ACM certificate ARN for HTTPS termination on the internal ALB"
}

output "external_dns_role_arn" {
  value       = aws_iam_role.external_dns.arn
  description = "IAM role ARN to annotate external-dns service account with IRSA"
}

output "db_endpoint" {
  value       = aws_db_instance.main.address
  description = "Private endpoint of the RDS instance"
}

output "db_port" {
  value       = aws_db_instance.main.port
  description = "Port exposed by the RDS instance"
}

output "db_name" {
  value       = var.db_name
  description = "Application database name"
}

output "db_username" {
  value       = var.db_username
  description = "Master username for the RDS instance"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "Secrets Manager ARN that stores generated DB credentials"
}

output "ecr_frontend_repository_url" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "ECR repository URL for frontend container images"
}

output "ecr_backend_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "ECR repository URL for backend container images"
}

output "github_actions_role_arn" {
  value       = var.github_actions_role_enabled ? aws_iam_role.github_actions[0].arn : null
  description = "IAM role ARN for GitHub Actions to assume via OIDC (set as AWS_ROLE_TO_ASSUME secret)"
}

output "argocd_fqdn" {
  value       = local.argocd_fqdn
  description = "Internal Argo CD URL hostname"
}

output "argocd_acm_certificate_arn" {
  value       = aws_acm_certificate.argocd_tls.arn
  description = "ACM certificate ARN for Argo CD internal ALB"
}