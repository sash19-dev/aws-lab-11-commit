data "aws_ami" "linux_mgmt" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}

resource "aws_security_group" "linux_mgmt" {
  count       = var.enable_linux_mgmt_instance ? 1 : 0
  name        = "${var.project}-linux-mgmt-sg"
  description = "Security group for temporary Linux management instance"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-linux-mgmt-sg"
  }
}

resource "aws_iam_role" "linux_mgmt" {
  count = var.enable_linux_mgmt_instance ? 1 : 0
  name  = "${var.project}-linux-mgmt-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "linux_mgmt_ssm" {
  count      = var.enable_linux_mgmt_instance ? 1 : 0
  role       = aws_iam_role.linux_mgmt[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "linux_mgmt_eks_access" {
  count = var.enable_linux_mgmt_instance ? 1 : 0
  name  = "${var.project}-linux-mgmt-eks-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "linux_mgmt_eks_access" {
  count      = var.enable_linux_mgmt_instance ? 1 : 0
  role       = aws_iam_role.linux_mgmt[0].name
  policy_arn = aws_iam_policy.linux_mgmt_eks_access[0].arn
}

resource "aws_iam_instance_profile" "linux_mgmt" {
  count = var.enable_linux_mgmt_instance ? 1 : 0
  name  = "${var.project}-linux-mgmt-instance-profile"
  role  = aws_iam_role.linux_mgmt[0].name
}

resource "aws_instance" "linux_mgmt" {
  count                  = var.enable_linux_mgmt_instance ? 1 : 0
  ami                    = data.aws_ami.linux_mgmt.id
  instance_type          = var.linux_mgmt_instance_type
  subnet_id              = aws_subnet.private[var.linux_mgmt_subnet_index].id
  vpc_security_group_ids = [aws_security_group.linux_mgmt[0].id]
  iam_instance_profile   = aws_iam_instance_profile.linux_mgmt[0].name

  tags = {
    Name = "${var.project}-linux-mgmt"
    Role = "eks-management"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_api_from_linux_mgmt" {
  count                        = var.enable_linux_mgmt_instance ? 1 : 0
  security_group_id            = aws_eks_cluster.lab_commit_eks_cluster.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.linux_mgmt[0].id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow Linux management host to reach EKS private API"
}

resource "aws_eks_access_entry" "linux_mgmt" {
  count         = var.enable_linux_mgmt_instance ? 1 : 0
  cluster_name  = aws_eks_cluster.lab_commit_eks_cluster.name
  principal_arn = aws_iam_role.linux_mgmt[0].arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "linux_mgmt_cluster_admin" {
  count         = var.enable_linux_mgmt_instance ? 1 : 0
  cluster_name  = aws_eks_cluster.lab_commit_eks_cluster.name
  principal_arn = aws_iam_role.linux_mgmt[0].arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.linux_mgmt]
}
