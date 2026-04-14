#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/codepipeline.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text); echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); PIPE_NAME="tut-pipe-${RANDOM_ID}"; BUCKET="codepipeline-tut-${RANDOM_ID}-${ACCOUNT}"; ROLE_NAME="codepipeline-tut-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws codepipeline delete-pipeline --name "$PIPE_NAME" 2>/dev/null && echo "  Deleted pipeline"; aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name pipe-policy 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; if aws s3 ls "s3://$BUCKET" > /dev/null 2>&1; then aws s3 rm "s3://$BUCKET" --recursive --quiet; aws s3 rb "s3://$BUCKET" && echo "  Deleted bucket"; fi; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating S3 bucket for artifacts"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
echo "  Bucket: $BUCKET"
echo "Step 2: Creating IAM role"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codepipeline.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name pipe-policy --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:*","codebuild:*","codecommit:*"],"Resource":"*"}]}'
echo "  Role: $ROLE_ARN"; sleep 10
echo "Step 3: Creating pipeline: $PIPE_NAME"
aws codepipeline create-pipeline --pipeline "{\"name\":\"$PIPE_NAME\",\"roleArn\":\"$ROLE_ARN\",\"artifactStore\":{\"type\":\"S3\",\"location\":\"$BUCKET\"},\"stages\":[{\"name\":\"Source\",\"actions\":[{\"name\":\"S3Source\",\"actionTypeId\":{\"category\":\"Source\",\"owner\":\"AWS\",\"provider\":\"S3\",\"version\":\"1\"},\"configuration\":{\"S3Bucket\":\"$BUCKET\",\"S3ObjectKey\":\"source.zip\",\"PollForSourceChanges\":\"false\"},\"outputArtifacts\":[{\"name\":\"SourceOutput\"}]}]},{\"name\":\"Deploy\",\"actions\":[{\"name\":\"S3Deploy\",\"actionTypeId\":{\"category\":\"Deploy\",\"owner\":\"AWS\",\"provider\":\"S3\",\"version\":\"1\"},\"configuration\":{\"BucketName\":\"$BUCKET\",\"Extract\":\"true\"},\"inputArtifacts\":[{\"name\":\"SourceOutput\"}]}]}]}" --query 'pipeline.name' --output text > /dev/null
echo "  Pipeline created"
echo "Step 4: Getting pipeline state"
aws codepipeline get-pipeline-state --name "$PIPE_NAME" --query 'stageStates[].{Stage:stageName,Status:latestExecution.status}' --output table 2>/dev/null || echo "  No executions yet"
echo "Step 5: Listing pipelines"
aws codepipeline list-pipelines --query 'pipelines[?starts_with(name, `tut-`)].{Name:name,Created:created}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
