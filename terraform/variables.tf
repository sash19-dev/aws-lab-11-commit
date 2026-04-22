variable "aws_region" {
  type        = string
  description = "The AWS region to deploy the resources"
  default     = "us-east-2"
}

variable "project" {
  type        = string
  description = "The project name"
  default     = "lab-commit"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR blocks for the public subnets"
  default     = ["10.20.0.0/20", "10.20.16.0/20"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR blocks for the private subnets"
  default     = ["10.20.32.0/20", "10.20.48.0/20"]
}

variable "eks_admin_principal_arn" {
  type        = string
  description = "IAM principal ARN (user or role) that should administer the EKS cluster"
}

variable "enable_linux_mgmt_instance" {
  type        = bool
  description = "Enable temporary Linux EC2 instance for EKS management"
  default     = true
}

variable "linux_mgmt_instance_type" {
  type        = string
  description = "EC2 instance type for Linux management host"
  default     = "t3.micro"
}

variable "linux_mgmt_subnet_index" {
  type        = number
  description = "Index of private subnet list for Linux management host placement"
  default     = 0
}

variable "enable_windows_mgmt_instance" {
  type        = bool
  description = "Enable private Windows EC2 instance for SSM-based application validation"
  default     = false
}

variable "windows_mgmt_instance_type" {
  type        = string
  description = "EC2 instance type for Windows management host"
  default     = "t3.medium"
}

variable "windows_mgmt_subnet_index" {
  type        = number
  description = "Index of private subnet list for Windows management host placement"
  default     = 1
}

variable "private_hosted_zone_name" {
  type        = string
  description = "Private Route53 hosted zone domain for internal services"
  default     = "lab-commit.internal"
}

variable "app_record_name" {
  type        = string
  description = "Record name prefix for the internal application URL"
  default     = "lab-commit-task"
}

variable "argocd_record_name" {
  type        = string
  description = "Record name prefix for the internal Argo CD URL"
  default     = "argocd"
}

variable "external_dns_namespace" {
  type        = string
  description = "Kubernetes namespace where external-dns service account will run"
  default     = "kube-system"
}

variable "external_dns_service_account_name" {
  type        = string
  description = "Kubernetes service account name used by external-dns"
  default     = "external-dns"
}

variable "db_engine" {
  type        = string
  description = "RDS engine name"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "RDS engine version"
  default     = "16.13"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS allocated storage size in GB"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Application database name"
  default     = "labcommit"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance"
  default     = "labcommit"
}

variable "db_port" {
  type        = number
  description = "Database listener port"
  default     = 5432
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "Tag mutability mode for ECR repositories"
  default     = "MUTABLE"
}

variable "ecr_max_images" {
  type        = number
  description = "Maximum number of images to keep per ECR repository"
  default     = 30
}

variable "github_repository_id" {
  type        = string
  description = "GitHub repository in owner/repo format (used for GitHub Actions OIDC trust)"
  default     = "sash19-dev/aws-lab-11-commit"
}

variable "github_actions_role_enabled" {
  type        = bool
  description = "Create IAM OIDC provider and role for GitHub Actions to assume via OIDC"
  default     = true
}

variable "github_actions_allowed_branches" {
  type        = list(string)
  description = "Git branches allowed to assume the GitHub Actions IAM role via OIDC"
  default     = ["main"]
}

