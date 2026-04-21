resource "aws_eks_cluster" "lab_commit_eks_cluster" {
  name = "lab-commit-eks-cluster"

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = false
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.lab_commit_eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_eks_fargate_profile" "lab_commit_eks_fargate_profile" {
  cluster_name           = aws_eks_cluster.lab_commit_eks_cluster.name
  fargate_profile_name   = "lab-commit-eks-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile_role.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "default"
  }
  selector {
    namespace = "app"
  }
  selector {
    namespace = "kube-system"
  }
  selector {
    namespace = "argocd"
  }
  depends_on = [aws_iam_role_policy_attachment.amazonEKSFargatePodExecutionRolePolicy]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.lab_commit_eks_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    tolerations = [
      {
        key      = "node-role.kubernetes.io/control-plane"
        effect   = "NoSchedule"
        operator = "Exists"
      },
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
      },
      {
        key      = "eks.amazonaws.com/compute-type"
        operator = "Equal"
        value    = "fargate"
        effect   = "NoSchedule"
      }
    ]
  })

  depends_on = [aws_eks_fargate_profile.lab_commit_eks_fargate_profile]
}


resource "aws_iam_role" "eks_fargate_profile_role" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "amazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_profile_role.name
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.lab_commit_eks_cluster.name
  principal_arn = var.eks_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_cluster_admin" {
  cluster_name  = aws_eks_cluster.lab_commit_eks_cluster.name
  principal_arn = var.eks_admin_principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}