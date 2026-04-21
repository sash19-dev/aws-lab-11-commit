#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform"
SQL_FILE="${ROOT_DIR}/k8s/sql/init_app_state.sql"
APP_NAMESPACE="${APP_NAMESPACE:-app}"
SECRET_NAME="${SECRET_NAME:-app-db}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd aws
require_cmd kubectl
require_cmd psql
require_cmd python3
require_cmd terraform

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "SQL file not found: ${SQL_FILE}" >&2
  exit 1
fi

DB_SECRET_ARN="$(terraform -chdir="${TF_DIR}" output -raw db_secret_arn)"

SECRET_JSON="$(
  aws secretsmanager get-secret-value \
    --secret-id "${DB_SECRET_ARN}" \
    --query 'SecretString' \
    --output text
)"

DB_HOST="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["host"])' <<<"${SECRET_JSON}")"
DB_PORT="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["port"])' <<<"${SECRET_JSON}")"
DB_NAME="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["dbname"])' <<<"${SECRET_JSON}")"
DB_USER="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["username"])' <<<"${SECRET_JSON}")"
DB_PASSWORD="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["password"])' <<<"${SECRET_JSON}")"

echo "Initializing schema in RDS database ${DB_NAME} at ${DB_HOST}:${DB_PORT}..."
PGPASSWORD="${DB_PASSWORD}" psql \
  "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER} sslmode=require" \
  -f "${SQL_FILE}"

echo "Upserting Kubernetes secret ${SECRET_NAME} in namespace ${APP_NAMESPACE}..."
kubectl create namespace "${APP_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic "${SECRET_NAME}" \
  --namespace "${APP_NAMESPACE}" \
  --from-literal=DB_HOST="${DB_HOST}" \
  --from-literal=DB_PORT="${DB_PORT}" \
  --from-literal=DB_NAME="${DB_NAME}" \
  --from-literal=DB_USER="${DB_USER}" \
  --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Done. DB initialized and Kubernetes secret ${APP_NAMESPACE}/${SECRET_NAME} is ready."
