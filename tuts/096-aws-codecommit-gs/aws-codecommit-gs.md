# Create a CodeCommit repository and manage code

This tutorial shows you how to create a CodeCommit repository, add files, create a branch, compare changes between branches, and retrieve repository metadata using the AWS CLI.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `codecommit:CreateRepository`, `codecommit:PutFile`, `codecommit:GetFile`, `codecommit:CreateBranch`, `codecommit:ListBranches`, `codecommit:GetDifferences`, `codecommit:GetRepository`, `codecommit:DeleteRepository`

## Step 1: Create a repository

```bash
aws codecommit create-repository --repository-name "$REPO_NAME" \
    --repository-description "Tutorial repository" \
    --query 'repositoryMetadata.{Name:repositoryName,Id:repositoryId}' --output table
```

CodeCommit returns the repository metadata including the name and unique ID.

## Step 2: Add a file

Write a file locally and upload it with `put-file`. Use `fileb://` to pass the file content as raw bytes:

```bash
echo -e "# Tutorial Repository\n\nThis is a sample file." > "$WORK_DIR/README.md"
COMMIT_ID=$(aws codecommit put-file \
    --repository-name "$REPO_NAME" \
    --branch-name main \
    --file-content "fileb://$WORK_DIR/README.md" \
    --file-path README.md \
    --commit-message "Initial commit" \
    --name "Tutorial User" \
    --email "tutorial@example.com" \
    --query 'commitId' --output text)
```

The `fileb://` prefix tells the CLI to read the file as raw binary. This creates the `main` branch with the first commit.

## Step 3: Get the file

Retrieve file metadata from the repository:

```bash
aws codecommit get-file --repository-name "$REPO_NAME" \
    --file-path README.md \
    --query '{Path:filePath,Size:fileSize,CommitId:commitId}' --output table
```

## Step 4: Create a branch

Create a branch from the current commit and list all branches:

```bash
aws codecommit create-branch --repository-name "$REPO_NAME" \
    --branch-name feature-branch --commit-id "$COMMIT_ID"
aws codecommit list-branches --repository-name "$REPO_NAME" \
    --query 'branches' --output table
```

## Step 5: Add a file to the branch

Add a new file to the feature branch. Pass `--parent-commit-id` to build on the branch tip:

```bash
echo "console.log('Hello from CodeCommit');" > "$WORK_DIR/index.js"
aws codecommit put-file \
    --repository-name "$REPO_NAME" \
    --branch-name feature-branch \
    --file-content "fileb://$WORK_DIR/index.js" \
    --file-path src/index.js \
    --commit-message "Add source file" \
    --parent-commit-id "$COMMIT_ID" \
    --query 'commitId' --output text
```

## Step 6: Compare branches

Use `get-differences` to see what changed between `main` and `feature-branch`:

```bash
aws codecommit get-differences \
    --repository-name "$REPO_NAME" \
    --before-commit-specifier main \
    --after-commit-specifier feature-branch \
    --query 'differences[].{Path:afterBlob.path,Type:changeType}' --output table
```

## Step 7: Get repository metadata

```bash
aws codecommit get-repository --repository-name "$REPO_NAME" \
    --query 'repositoryMetadata.{Name:repositoryName,DefaultBranch:defaultBranch,Created:creationDate}' \
    --output table
```

## Cleanup

Delete the repository. This removes all branches, files, and commit history:

```bash
aws codecommit delete-repository --repository-name "$REPO_NAME"
```

The script automates all steps including cleanup:

```bash
bash aws-codecommit-gs.sh
```
