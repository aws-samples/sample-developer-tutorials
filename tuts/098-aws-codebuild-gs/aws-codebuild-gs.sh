#!/bin/bash
# Tutorial: Create a build project and run a build with AWS CodeBuild
# Source: https://docs.aws.amazon.com/codebuild/latest/userguide/getting-started-cli.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/codebuild-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
BUCKET_NAME="codebuild-tut-${RANDOM_ID}-${ACCOUNT_ID}"
PROJECT_NAME="tut-build-${RANDOM_ID}"
ROLE_NAME="codebuild-tut-role-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws codebuild delete-project --name "$PROJECT_NAME" 2>/dev/null && echo "  Deleted project $PROJECT_NAME"
    if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
        aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null && echo "  Deleted bucket $BUCKET_NAME"
    fi
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null
    aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name codebuild-logs 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    aws logs delete-log-group --log-group-name "/aws/codebuild/$PROJECT_NAME" 2>/dev/null && echo "  Deleted log group"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create S3 bucket for build artifacts
echo "Step 1: Creating S3 bucket: $BUCKET_NAME"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi

# Step 2: Create source files and upload
echo "Step 2: Creating source files"
mkdir -p "$WORK_DIR/src"
cat > "$WORK_DIR/src/buildspec.yml" << 'EOF'
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
cat > "$WORK_DIR/src/index.html" << 'EOF'
<html><body><h1>Built by CodeBuild</h1></body></html>
EOF
(cd "$WORK_DIR/src" && zip -r "$WORK_DIR/source.zip" . > /dev/null)
aws s3 cp "$WORK_DIR/source.zip" "s3://$BUCKET_NAME/source.zip" --quiet
echo "  Source uploaded to s3://$BUCKET_NAME/source.zip"

# Step 3: Create IAM role for CodeBuild
echo "Step 3: Creating IAM role: $ROLE_NAME"
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
echo "  Role ARN: $ROLE_ARN"
sleep 10

# Step 4: Create build project
echo "Step 4: Creating build project: $PROJECT_NAME"
aws codebuild create-project \
    --name "$PROJECT_NAME" \
    --source "type=S3,location=$BUCKET_NAME/source.zip" \
    --artifacts "type=S3,location=$BUCKET_NAME,path=output" \
    --environment "type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/amazonlinux-x86_64-standard:5.0" \
    --service-role "$ROLE_ARN" \
    --query 'project.{Name:name,Created:created}' --output table

# Step 5: Start a build
echo "Step 5: Starting build"
BUILD_ID=$(aws codebuild start-build --project-name "$PROJECT_NAME" \
    --query 'build.id' --output text)
echo "  Build ID: $BUILD_ID"

# Step 6: Wait for build to complete
echo "Step 6: Waiting for build to complete..."
for i in $(seq 1 30); do
    STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" \
        --query 'builds[0].buildStatus' --output text)
    echo "  Status: $STATUS"
    [ "$STATUS" = "SUCCEEDED" ] || [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "STOPPED" ] && break
    sleep 10
done

if [ "$STATUS" = "SUCCEEDED" ]; then
    echo "  Build succeeded!"
    echo "  Artifacts: s3://$BUCKET_NAME/output/"
    aws s3 ls "s3://$BUCKET_NAME/output/" --recursive 2>/dev/null | head -5
else
    echo "  Build did not succeed: $STATUS"
fi

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws codebuild delete-project --name $PROJECT_NAME"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive && aws s3 rb s3://$BUCKET_NAME"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess"
    echo "  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name codebuild-logs"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
