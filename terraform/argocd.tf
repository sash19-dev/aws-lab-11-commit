locals {
  argocd_fqdn = "${var.argocd_record_name}.${var.private_hosted_zone_name}"
}

resource "tls_private_key" "argocd_tls" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "argocd_tls" {
  private_key_pem = tls_private_key.argocd_tls.private_key_pem

  subject {
    common_name  = local.argocd_fqdn
    organization = "Lab Commit"
  }

  validity_period_hours = 24 * 365
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [local.argocd_fqdn]
}

resource "aws_acm_certificate" "argocd_tls" {
  private_key      = tls_private_key.argocd_tls.private_key_pem
  certificate_body = tls_self_signed_cert.argocd_tls.cert_pem

  tags = {
    Name = "${var.project}-argocd-cert"
  }
}
