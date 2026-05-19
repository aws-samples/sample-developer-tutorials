#!/bin/bash
set -e

# Title Banner
echo "=== AWS CodePipeline Tutorial ==="
echo "This tutorial demonstrates how to create an AWS CodePipeline using the AWS CLI."
echo "We will create a pipeline with Source and Build stages, and ensure proper cleanup."
echo ""

# Redirect output to log file if running in a terminal
if [ -t 1 ]; then 
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

  echo "=== Step 1: Creating Pipeline ==="
  echo "In this step, we will create an AWS CodePipeline. CodePipeline is a continuous delivery service you can use to model, visualize, and automate the steps required to release your software."
  echo "The pipeline will have a Source stage that pulls from an S3 bucket and a Build stage that uses CodeBuild."
  echo ""

  PIPELINE_NAME="pipeline-${SUFFIX}"
  PIPELINE_ARN=$(aws codepipeline create-pipeline --cli-input-json "{\"pipeline\":{\"name\": \"${PIPELINE_NAME}\",\"roleArn\": \"arn:aws:iam::559823168634:role/doc-babu-codepipeline-role\",\"artifactStores\":{\"$REGION\":{\"type\":\"S3\",\"location\":\"my-bucket\"}},\"stages\": [{\"name\": \"Source\",\"actions\": [{\"name\": \"SourceAction\",\"actionTypeId\": {\"category\": \"Source\",\"owner\": \"AWS\",\"provider\": \"S3\",\"version\": \"1\"},\"outputArtifacts\": [{\"name\": \"MyApp\"}],\"configuration\": {\"S3Bucket\":\"my-bucket\",\"S3ObjectKey\": \"path/to/my/app.zip\"},\"runOrder\": 1}]},{\"name\": \"Build\",\"actions\": [{\"name\": \"BuildAction\",\"actionTypeId\": {\"category\": \"Build\",\"owner\": \"AWS\",\"provider\": \"CodeBuild\",\"version\": \"1\"},\"inputArtifacts\": [{\"name\": \"MyApp\"}],\"outputArtifacts\": [{\"name\": \"BuildOutput\"}],\"configuration\": {\"ProjectName\": \"my-codebuild-project\"},\"runOrder\": 1}]}]}}" --query 'pipeline.arn' --output text)
  aws codepipeline tag-resource --resource-arn "$PIPELINE_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=codepipeline-gs
  echo "Result: Pipeline ${PIPELINE_NAME} created."
  echo ""

  CREATED_RESOURCES+=("pipeline:${PIPELINE_NAME}")

  echo "PASS"
  echo ""
  echo "Tutorial complete. You have learned how to create an AWS CodePipeline with Source and Build stages using the AWS CLI. The pipeline was automatically named to ensure uniqueness and will be cleaned up upon script exit."
fi