#!/bin/bash
set -e
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
echo "=== Creating Project ==="
cat > "$TEMP_DIR/create.json" << 'ENDJSON'
{"name":"build-PLACEHOLDER","source":{"type":"NO_SOURCE","buildspec":"version: 0.2\nphases:\n  build:\n    commands:\n      - echo hello"},"artifacts":{"type":"NO_ARTIFACTS"},"environment":{"type":"LINUX_CONTAINER","image":"aws/codebuild/standard:7.0","computeType":"BUILD_GENERAL1_SMALL"},"serviceRole":"arn:aws:iam::559823168634:role/doc-babu-codebuild-role"}
ENDJSON
sed -i "s/PLACEHOLDER/$SUFFIX/" "$TEMP_DIR/create.json"
aws codebuild create-project --cli-input-json "file://$TEMP_DIR/create.json" --query 'project.arn' --output text
CREATED_RESOURCES+=("project:build-$SUFFIX")
echo "=== Starting Build ==="
BUILD_ID=$(aws codebuild start-build --project-name "build-$SUFFIX" --query 'build.id' --output text)
echo "Build: $BUILD_ID"
echo "=== Tutorial Complete ==="