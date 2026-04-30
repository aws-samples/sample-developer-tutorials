#!/bin/bash
# Tutorial: Create a CodeCommit repository and manage code
# Source: https://docs.aws.amazon.com/codecommit/latest/userguide/getting-started-cc.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/codecommit-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
REPO_NAME="tutorial-repo-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws codecommit delete-repository --repository-name "$REPO_NAME" > /dev/null 2>&1 && \
        echo "  Deleted repository $REPO_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a repository
echo "Step 1: Creating repository: $REPO_NAME"
aws codecommit create-repository --repository-name "$REPO_NAME" \
    --repository-description "Tutorial repository" \
    --query 'repositoryMetadata.{Name:repositoryName,Id:repositoryId}' --output table

# Step 2: Add a file
echo "Step 2: Adding a file to the repository"
echo -e "# Tutorial Repository\n\nThis is a sample file created by the CodeCommit tutorial." > "$WORK_DIR/README.md"
COMMIT_ID=$(aws codecommit put-file \
    --repository-name "$REPO_NAME" \
    --branch-name main \
    --file-content "fileb://$WORK_DIR/README.md" \
    --file-path README.md \
    --commit-message "Initial commit" \
    --name "Tutorial User" \
    --email "tutorial@example.com" \
    --query 'commitId' --output text)
echo "  Commit: $COMMIT_ID"

# Step 3: Get the file
echo "Step 3: Retrieving the file"
aws codecommit get-file --repository-name "$REPO_NAME" \
    --file-path README.md \
    --query '{Path:filePath,Size:fileSize,CommitId:commitId}' --output table

# Step 4: Create a branch
echo "Step 4: Creating a branch"
aws codecommit create-branch --repository-name "$REPO_NAME" \
    --branch-name feature-branch --commit-id "$COMMIT_ID"
aws codecommit list-branches --repository-name "$REPO_NAME" \
    --query 'branches' --output table

# Step 5: Add a file to the branch
echo "Step 5: Adding a file to the feature branch"
echo "console.log('Hello from CodeCommit');" > "$WORK_DIR/index.js"
aws codecommit put-file \
    --repository-name "$REPO_NAME" \
    --branch-name feature-branch \
    --file-content "fileb://$WORK_DIR/index.js" \
    --file-path src/index.js \
    --commit-message "Add source file" \
    --parent-commit-id "$COMMIT_ID" \
    --query 'commitId' --output text > /dev/null
echo "  File added to feature-branch"

# Step 6: Get differences between branches
echo "Step 6: Comparing branches"
aws codecommit get-differences \
    --repository-name "$REPO_NAME" \
    --before-commit-specifier main \
    --after-commit-specifier feature-branch \
    --query 'differences[].{Path:afterBlob.path,Type:changeType}' --output table

# Step 7: Get repository metadata
echo "Step 7: Repository metadata"
aws codecommit get-repository --repository-name "$REPO_NAME" \
    --query 'repositoryMetadata.{Name:repositoryName,DefaultBranch:defaultBranch,Created:creationDate}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws codecommit delete-repository --repository-name $REPO_NAME"
fi
