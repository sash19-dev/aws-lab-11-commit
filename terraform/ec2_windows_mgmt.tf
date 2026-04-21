data "aws_ami" "windows_mgmt" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "windows_mgmt" {
  count       = var.enable_windows_mgmt_instance ? 1 : 0
  name        = "${var.project}-windows-mgmt-sg"
  description = "Security group for private Windows management instance"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-windows-mgmt-sg"
  }
}

resource "aws_iam_role" "windows_mgmt" {
  count = var.enable_windows_mgmt_instance ? 1 : 0
  name  = "${var.project}-windows-mgmt-role"

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

resource "aws_iam_role_policy_attachment" "windows_mgmt_ssm" {
  count      = var.enable_windows_mgmt_instance ? 1 : 0
  role       = aws_iam_role.windows_mgmt[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "windows_mgmt" {
  count = var.enable_windows_mgmt_instance ? 1 : 0
  name  = "${var.project}-windows-mgmt-instance-profile"
  role  = aws_iam_role.windows_mgmt[0].name
}

resource "aws_instance" "windows_mgmt" {
  count                  = var.enable_windows_mgmt_instance ? 1 : 0
  ami                    = data.aws_ami.windows_mgmt.id
  instance_type          = var.windows_mgmt_instance_type
  subnet_id              = aws_subnet.private[var.windows_mgmt_subnet_index].id
  vpc_security_group_ids = [aws_security_group.windows_mgmt[0].id]
  iam_instance_profile   = aws_iam_instance_profile.windows_mgmt[0].name

  tags = {
    Name = "${var.project}-windows-mgmt"
    Role = "application-validation"
  }
}
