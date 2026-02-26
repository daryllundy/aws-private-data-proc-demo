#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <bucket-name> [file-path]" >&2
  exit 1
fi

BUCKET_NAME="$1"
FILE_PATH="${2:-./sensitive_data.txt}"
OBJECT_KEY="sensitive_data.txt"

if [[ ! -f "${FILE_PATH}" ]]; then
  echo "Input file not found: ${FILE_PATH}" >&2
  exit 1
fi

aws s3 cp "${FILE_PATH}" "s3://${BUCKET_NAME}/${OBJECT_KEY}"
echo "Uploaded ${FILE_PATH} to s3://${BUCKET_NAME}/${OBJECT_KEY}"
