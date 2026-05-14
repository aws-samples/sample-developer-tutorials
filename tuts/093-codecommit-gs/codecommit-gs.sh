#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        TYPE_ID=(${CREATED_RESOURCES[$i]})
        case ${TYPE_ID[0]} in
            "repo")
                aws codecommit delete-repository --repository-name "${TYPE_ID[1]}" || true
                ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Creating repository ==="
REPO_NAME="test-repo-${SUFFIX}"
aws codecommit create-repository --repository-name "${REPO_NAME}" > "$LOG_FILE" 2>&1
if grep -q 'repositoryName' "$LOG_FILE"; then
    echo "PASS"
    CREATED_RESOURCES+=("repo:$REPO_NAME")
else
    echo "Failed to retrieve repository ARN."
    exit 1
fi