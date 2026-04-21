locals {
  app_fqdn = "${var.app_record_name}.${var.private_hosted_zone_name}"
}

resource "aws_route53_zone" "private" {
  name = var.private_hosted_zone_name

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name = "${var.project}-private-zone"
  }
}

resource "tls_private_key" "app_tls" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_tls" {
  private_key_pem = tls_private_key.app_tls.private_key_pem

  subject {
    common_name  = local.app_fqdn
    organization = "Lab Commit"
  }

  validity_period_hours = 24 * 365
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [local.app_fqdn]
}

resource "aws_acm_certificate" "app_tls" {
  private_key      = tls_private_key.app_tls.private_key_pem
  certificate_body = tls_self_signed_cert.app_tls.cert_pem

  tags = {
    Name = "${var.project}-internal-app-cert"
  }
}

data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.project}-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json
}

data "aws_iam_policy_document" "external_dns_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [aws_route53_zone.private.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]
    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "${var.project}-external-dns-policy"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns_permissions.json
}
