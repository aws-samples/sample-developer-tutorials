#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

function cleanup_resources {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[$i]})
        case ${RESOURCE[0]} in
            pipeline) aws codepipeline delete-pipeline --name "${RESOURCE[1]}" ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "=== Creating Pipeline ==="
PIPELINE_NAME="pipeline-${SUFFIX}"
aws codepipeline create-pipeline --cli-input-json "{\"pipeline\":{\"name\": \"${PIPELINE_NAME}\",\"roleArn\": \"arn:aws:iam::559823168634:role/doc-babu-codepipeline-role\",\"artifactStores\":{\"$REGION\":{\"type\":\"S3\",\"location\":\"my-bucket\"}},\"stages\": [{\"name\": \"Source\",\"actions\": [{\"name\": \"SourceAction\",\"actionTypeId\": {\"category\": \"Source\",\"owner\": \"AWS\",\"provider\": \"S3\",\"version\": \"1\"},\"outputArtifacts\": [{\"name\": \"MyApp\"}],\"configuration\": {\"S3Bucket\":\"my-bucket\",\"S3ObjectKey\": \"path/to/my/app.zip\"},\"runOrder\": 1}]},{\"name\": \"Build\",\"actions\": [{\"name\": \"BuildAction\",\"actionTypeId\": {\"category\": \"Build\",\"owner\": \"AWS\",\"provider\": \"CodeBuild\",\"version\": \"1\"},\"inputArtifacts\": [{\"name\": \"MyApp\"}],\"outputArtifacts\": [{\"name\": \"BuildOutput\"}],\"configuration\": {\"ProjectName\": \"my-codebuild-project\"},\"runOrder\": 1}]}]}}" >> "$LOG_FILE"
CREATED_RESOURCES+=("pipeline:${PIPELINE_NAME}")

echo "PASS"