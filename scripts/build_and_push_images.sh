#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform"
TAG="${1:-v1.0.0}"
REGION="${AWS_REGION:-us-east-2}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd aws
require_cmd docker
require_cmd terraform

FRONTEND_REPO="$(terraform -chdir="${TF_DIR}" output -raw ecr_frontend_repository_url)"
BACKEND_REPO="$(terraform -chdir="${TF_DIR}" output -raw ecr_backend_repository_url)"
REGISTRY="${FRONTEND_REPO%/*}"

echo "Logging in to ECR ${REGISTRY}..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"

echo "Building backend image..."
docker build -t "${BACKEND_REPO}:${TAG}" "${ROOT_DIR}/backend"
docker push "${BACKEND_REPO}:${TAG}"

echo "Building frontend image..."
docker build -t "${FRONTEND_REPO}:${TAG}" "${ROOT_DIR}/frontend"
docker push "${FRONTEND_REPO}:${TAG}"

cat <<EOF
Images pushed successfully:
  ${BACKEND_REPO}:${TAG}
  ${FRONTEND_REPO}:${TAG}
EOF
