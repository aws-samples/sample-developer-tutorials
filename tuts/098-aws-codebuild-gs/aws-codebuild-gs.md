# Create a build project and run a build with AWS CodeBuild

This tutorial shows you how to create an S3 bucket for source and artifacts, create source files, configure an IAM role, create a CodeBuild project, run a build, and verify the output.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `codebuild:CreateProject`, `codebuild:StartBuild`, `codebuild:BatchGetBuilds`, `codebuild:DeleteProject`, `s3:CreateBucket`, `s3:PutObject`, `s3:GetObject`, `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PutRolePolicy`, `iam:DeleteRole`

## Step 1: Create an S3 bucket

Create a bucket to hold the build source and output artifacts:

```bash
BUCKET_NAME="codebuild-tut-${RANDOM_ID}-${ACCOUNT_ID}"
aws s3api create-bucket --bucket "$BUCKET_NAME" \
    --create-bucket-configuration LocationConstraint="$REGION"
```

For `us-east-1`, omit the `--create-bucket-configuration` parameter.

## Step 2: Create source files and upload

Create a `buildspec.yml` that defines the build commands and an `index.html` as sample content. Package them into a zip and upload to S3:

```bash
cat > buildspec.yml << 'EOF'
version: 0.2
phases:
  build:
    commands:
      - echo "Build started on $(date)"
      - echo "Hello from CodeBuild"
      - echo "Build completed"
artifacts:
  files:
    - '**/*'
EOF

cat > index.html << 'EOF'
<html><body><h1>Built by CodeBuild</h1></body></html>
EOF

zip source.zip buildspec.yml index.html
aws s3 cp source.zip "s3://$BUCKET_NAME/source.zip"
```

The `buildspec.yml` tells CodeBuild what commands to run and which files to include in the output artifacts.

## Step 3: Create an IAM role for CodeBuild

Create a service role that allows CodeBuild to access S3 and write logs:

```bash
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"codebuild.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)

aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name codebuild-logs \
    --policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],"Resource":"*"}]
    }'
```

Wait about 10 seconds for the role to propagate before using it.

## Step 4: Create a build project

Create a project that reads source from S3 and writes artifacts back to S3:

```bash
aws codebuild create-project \
    --name "$PROJECT_NAME" \
    --source "type=S3,location=$BUCKET_NAME/source.zip" \
    --artifacts "type=S3,location=$BUCKET_NAME,path=output" \
    --environment "type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/amazonlinux-x86_64-standard:5.0" \
    --service-role "$ROLE_ARN" \
    --query 'project.{Name:name,Created:created}' --output table
```

The environment uses a managed Amazon Linux image with standard build tools.

## Step 5: Start a build

```bash
BUILD_ID=$(aws codebuild start-build --project-name "$PROJECT_NAME" \
    --query 'build.id' --output text)
echo "Build ID: $BUILD_ID"
```

## Step 6: Wait for build completion and check artifacts

Poll the build status until it completes:

```bash
STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" \
    --query 'builds[0].buildStatus' --output text)
```

When the status is `SUCCEEDED`, list the output artifacts:

```bash
aws s3 ls "s3://$BUCKET_NAME/output/" --recursive
```

## Cleanup

Delete the build project, empty and remove the S3 bucket, detach policies and delete the IAM role, and delete the CloudWatch log group:

```bash
aws codebuild delete-project --name "$PROJECT_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive
aws s3 rb "s3://$BUCKET_NAME"
aws iam detach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name codebuild-logs
aws iam delete-role --role-name "$ROLE_NAME"
aws logs delete-log-group --log-group-name "/aws/codebuild/$PROJECT_NAME"
```

The script automates all steps including cleanup:

```bash
bash aws-codebuild-gs.sh
```
