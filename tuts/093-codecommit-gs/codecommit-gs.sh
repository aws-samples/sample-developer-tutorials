#!/bin/bash
# Create a Git repository and manage code
# Resources created: AWS CodeCommit repository

set -euo pipefail

UNIQUE_ID=$(date +%s | sha256sum | base64 | head -c 8)
LOG_FILE="codecommit-tutorial-${UNIQUE_ID}.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

check_error() {
 if echo "$1" | grep -iqE "error|failed"; then
 echo "ERROR in $2: $1" >&2
 return 1
 fi
}

declare -a CREATED_RESOURCES=()

cleanup_resources() {
 echo "=== Cleaning up resources ==="
 for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
 resource="${CREATED_RESOURCES[$i]}"
 IFS=':' read -r type name <<< "$resource"
 echo "Deleting $type: $name"
 if [[ "$type" == "repository" ]]; then
 aws codecommit delete-repository --repository-name "$name" || true
 fi
 done
}
trap cleanup_resources EXIT

# Region check
if [[ -z "$(aws configure get region 2>/dev/null)" ]] && [[ -z "${AWS_DEFAULT_REGION:-}" ]] && [[ -z "${AWS_REGION:-}" ]]; then
 echo "ERROR: No AWS region configured"
 exit 1
fi

# Credentials check
aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: Invalid credentials"; exit 1; }

echo "=== Step 1: Create resources ==="
REPOSITORY_NAME="codecommit-repo-$UNIQUE_ID"
aws codecommit create-repository --repository-name "$REPOSITORY_NAME" --tags Key=tutorial,Value=codecommit-gs
check_error "$?" "create-repository"
CREATED_RESOURCES+=("repository:$REPOSITORY_NAME")

echo "=== Step 2: Manage code ==="
BRANCH_NAME="main"
FILE_CONTENT=$(base64 /test-files/a.txt)
FILE_PATH="hello.txt"

aws codecommit put-file --repository-name "$REPOSITORY_NAME" --branch-name "$BRANCH_NAME" --file-content "$FILE_CONTENT" --file-path "$FILE_PATH"
check_error "$?" "put-file"

FILE_CONTENT_RETRIEVED=$(aws codecommit get-file --repository-name "$REPOSITORY_NAME" --file-path "$FILE_PATH" --query 'fileContent' --output text)
echo "Retrieved file content: $FILE_CONTENT_RETRIEVED"
check_error "$?" "get-file"

echo "=== Step 3: Verify ==="
aws codecommit get-branch --repository-name "$REPOSITORY_NAME" --branch-name "$BRANCH_NAME"
check_error "$?" "get-branch"

echo "=== Summary ==="
echo "Created repository: $REPOSITORY_NAME"
echo "Added file: $FILE_PATH with content from /test-files/a.txt"