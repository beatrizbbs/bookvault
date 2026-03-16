#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-prod}"
IMAGE_TAG="${2:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-bookvault}"
ECR_REPOSITORY="${ECR_REPOSITORY:-bookvault-api}"
TF_STATE_BUCKET="${TF_STATE_BUCKET:-}"
TF_LOCK_TABLE="${TF_LOCK_TABLE:-}"
TF_ENV_DIR="terraform/environments/${ENVIRONMENT}"
CONTAINER_SECRETS_JSON="${CONTAINER_SECRETS_JSON:-}"
SECRETS_ACCESS_ARNS_JSON="${SECRETS_ACCESS_ARNS_JSON:-}"

usage() {
  cat <<USAGE
Usage: ./scripts/deploy.sh [environment] [image_tag]

Arguments:
  environment   Terraform environment directory (default: prod)
  image_tag     Container tag to deploy (default: git short SHA)

Required environment variables:
  TF_STATE_BUCKET   Terraform backend S3 bucket name
  TF_LOCK_TABLE     Terraform backend DynamoDB lock table name

Optional environment variables:
  AWS_REGION        AWS region (default: us-east-1)
  PROJECT_NAME      Project name (default: bookvault)
  ECR_REPOSITORY    ECR repository name (default: bookvault-api)
  CONTAINER_SECRETS_JSON     JSON for Terraform var container_secrets
  SECRETS_ACCESS_ARNS_JSON   JSON for Terraform var secrets_access_arns
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

for cmd in terraform aws docker; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "${cmd} is required"
    exit 1
  fi
done

if [[ ! -d "${TF_ENV_DIR}" ]]; then
  echo "Terraform environment directory not found: ${TF_ENV_DIR}"
  exit 1
fi

if [[ -z "${TF_STATE_BUCKET}" || -z "${TF_LOCK_TABLE}" ]]; then
  echo "TF_STATE_BUCKET and TF_LOCK_TABLE must be set"
  exit 1
fi

TF_VAR_ARGS=()
if [[ -n "${CONTAINER_SECRETS_JSON}" ]]; then
  TF_VAR_ARGS+=("-var=container_secrets=${CONTAINER_SECRETS_JSON}")
fi
if [[ -n "${SECRETS_ACCESS_ARNS_JSON}" ]]; then
  TF_VAR_ARGS+=("-var=secrets_access_arns=${SECRETS_ACCESS_ARNS_JSON}")
fi

echo "Initializing Terraform in ${TF_ENV_DIR}"
terraform -chdir="${TF_ENV_DIR}" init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
  -backend-config="region=${AWS_REGION}" \
  -input=false

echo "Applying infrastructure (pass 1)"
terraform -chdir="${TF_ENV_DIR}" apply -auto-approve -input=false \
  -var="aws_region=${AWS_REGION}" \
  -var="project_name=${PROJECT_NAME}" \
  -var="environment=${ENVIRONMENT}" \
  -var="ecr_repository_name=${ECR_REPOSITORY}" \
  -var="container_image_tag=bootstrap" \
  "${TF_VAR_ARGS[@]}"

ECR_REPOSITORY_URL="$(terraform -chdir="${TF_ENV_DIR}" output -raw ecr_repository_url)"
IMAGE_URI="${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
ECR_REGISTRY="$(echo "${ECR_REPOSITORY_URL}" | cut -d'/' -f1)"

echo "Logging in to ECR ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "Building and pushing image ${IMAGE_URI}"
./scripts/build.sh --image-name "${ECR_REPOSITORY}" --tag "${IMAGE_TAG}" --context api --push --image-uri "${IMAGE_URI}"

echo "Applying infrastructure (pass 2 with image tag ${IMAGE_TAG})"
terraform -chdir="${TF_ENV_DIR}" apply -auto-approve -input=false \
  -var="aws_region=${AWS_REGION}" \
  -var="project_name=${PROJECT_NAME}" \
  -var="environment=${ENVIRONMENT}" \
  -var="ecr_repository_name=${ECR_REPOSITORY}" \
  -var="container_image_tag=${IMAGE_TAG}" \
  "${TF_VAR_ARGS[@]}"

CLUSTER_NAME="$(terraform -chdir="${TF_ENV_DIR}" output -raw ecs_cluster_name)"
SERVICE_NAME="$(terraform -chdir="${TF_ENV_DIR}" output -raw ecs_service_name)"

echo "Forcing ECS rolling deployment for ${CLUSTER_NAME}/${SERVICE_NAME}"
aws ecs update-service \
  --region "${AWS_REGION}" \
  --cluster "${CLUSTER_NAME}" \
  --service "${SERVICE_NAME}" \
  --force-new-deployment >/dev/null

echo "Deployment completed"
echo "Environment: ${ENVIRONMENT}"
echo "Image: ${IMAGE_URI}"
echo "Service: ${CLUSTER_NAME}/${SERVICE_NAME}"
