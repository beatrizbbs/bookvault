#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="bookvault-api"
IMAGE_TAG="latest"
CONTEXT_DIR="api"
DO_PUSH="false"
IMAGE_URI=""

usage() {
  cat <<USAGE
Usage: ./scripts/build.sh [options]

Options:
  --image-name <name>   Local image name (default: bookvault-api)
  --tag <tag>           Image tag (default: latest)
  --context <dir>       Docker build context (default: api)
  --push                Push image after build (requires --image-uri)
  --image-uri <uri>     Full remote image URI (example: 123.dkr.ecr.us-east-1.amazonaws.com/bookvault-api:sha)
  -h, --help            Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --context)
      CONTEXT_DIR="$2"
      shift 2
      ;;
    --push)
      DO_PUSH="true"
      shift
      ;;
    --image-uri)
      IMAGE_URI="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required"
  exit 1
fi

LOCAL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building ${LOCAL_IMAGE} from ${CONTEXT_DIR}"
docker build -t "${LOCAL_IMAGE}" "${CONTEXT_DIR}"

if [[ "${DO_PUSH}" == "true" ]]; then
  if [[ -z "${IMAGE_URI}" ]]; then
    echo "--image-uri is required when --push is used"
    exit 1
  fi

  echo "Tagging ${LOCAL_IMAGE} as ${IMAGE_URI}"
  docker tag "${LOCAL_IMAGE}" "${IMAGE_URI}"

  echo "Pushing ${IMAGE_URI}"
  docker push "${IMAGE_URI}"
fi

echo "Build script completed"
