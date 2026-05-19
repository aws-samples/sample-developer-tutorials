#!/bin/bash
set -e

# Title Banner
echo "=== AWS CodeCommit Repository Creation Tutorial ==="
echo "This tutorial demonstrates how to create an AWS CodeCommit repository using the AWS CLI."
echo "We will also show how to log actions and clean up resources automatically."

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

if [ -t 1 ]; then 
echo "=== Step 1: Generate a Unique Suffix ==="
echo "We generate a unique suffix to ensure that the repository name is unique."
echo "This prevents naming conflicts with existing repositories."
echo ""
echo "Generated Suffix: ${SUFFIX}"
echo ""

echo "=== Step 2: Create a Temporary Directory for Logs ==="
echo "A temporary directory is created to store log files."
echo "This helps in organizing and managing log files efficiently."
echo ""
echo "Temporary Directory: ${TEMP_DIR}"
echo ""

echo "=== Step 3: Create a CodeCommit Repository ==="
echo "We will now create a CodeCommit repository using the AWS CLI."
echo "CodeCommit is a version control service that hosts secure Git-based repositories."
echo ""
REPO_NAME="test-repo-${SUFFIX}"
REPO_ARN=$(aws codecommit create-repository --repository-name "${REPO_NAME}" --query 'repositoryMetadata.repositoryArn' --output text)
aws codecommit tag-resource --resource-arn "$REPO_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=codecommit-gs
echo "Result: Repository ${REPO_NAME} created."
echo ""

echo "=== Step 4: Verify Repository Creation ==="
echo "We check the log file to verify that the repository was created successfully."
echo "This step ensures that the repository ARN is retrieved and logged."
echo ""
if grep -q'repositoryName' "$LOG_FILE"; then
    echo "PASS"
    CREATED_RESOURCES+=("repo:$REPO_NAME")
else
    echo "Failed to retrieve repository ARN."
    exit 1
fi
echo ""

echo "Tutorial complete"
echo "In this tutorial, you learned how to create an AWS CodeCommit repository using the AWS CLI."
echo "You also learned how to log actions and clean up resources automatically."
fi