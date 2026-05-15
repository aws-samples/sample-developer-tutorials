#!/bin/bash
set -e
LOG_FILE="tutorial.log"
if [ -t 1 ]; then 
echo "=== AWS CodeBuild Tutorial: Creating and Starting a Build Project ==="
echo "This tutorial will guide you through creating a CodeBuild project and starting a build."
echo "You will learn how to use AWS CLI commands to manage CodeBuild resources."
echo ""
fi

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            project) aws codebuild delete-project --name "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Step 1: Generating a Unique Suffix ==="
echo "We generate a unique suffix to ensure that the project name is unique."
echo "This prevents conflicts with existing projects."
echo ""
echo "Result: $SUFFIX"
echo ""

echo "=== Step 2: Creating a Temporary Directory ==="
echo "A temporary directory is created to store our JSON configuration file."
echo "This directory will be cleaned up at the end of the tutorial."
echo ""
echo "Result: $TEMP_DIR"
echo ""

echo "=== Step 3: Creating the Project Configuration File ==="
echo "We create a JSON file that defines the CodeBuild project configuration."
echo "This includes the project name, source details, artifacts, environment, and service role."
echo ""
cat > "$TEMP_DIR/create.json" << 'ENDJSON'
{"name":"build-PLACEHOLDER","source":{"type":"NO_SOURCE","buildspec":"version: 0.2\nphases:\n  build:\n    commands:\n      - echo hello"},"artifacts":{"type":"NO_ARTIFACTS"},"environment":{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:7.0","computeType":"BUILD_GENERAL1_SMALL"},"serviceRole":"arn:aws:iam::559823168634:role/doc-babu-codebuild-role"}
ENDJSON
echo "Result: Configuration file created at $TEMP_DIR/create.json"
echo ""

echo "=== Step 4: Replacing Placeholder with Unique Suffix ==="
echo "We replace the placeholder in the JSON file with the unique suffix to create a unique project name."
echo ""
sed -i "s/PLACEHOLDER/$SUFFIX/" "$TEMP_DIR/create.json"
echo "Result: Placeholder replaced with $SUFFIX"
echo ""

echo "=== Step 5: Creating the CodeBuild Project ==="
echo "We use the AWS CLI to create a CodeBuild project using the configuration file."
echo "This will set up the project with the specified settings."
echo ""
PROJECT_ARN=$(aws codebuild create-project --cli-input-json "file://$TEMP_DIR/create.json" --query 'project.arn' --output text)
CREATED_RESOURCES+=("project:build-$SUFFIX")
echo "Result: Project ARN: $PROJECT_ARN"
echo ""

echo "=== Step 6: Starting the Build ==="
echo "We start a build for the newly created project."
echo "This will execute the buildspec defined in the project configuration."
echo ""
BUILD_ID=$(aws codebuild start-build --project-name "build-$SUFFIX" --query 'build.id' --output text)
echo "Result: Build ID: $BUILD_ID"
echo ""