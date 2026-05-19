#!/bin/bash
set -e

cleanup_resources() {
  for res in "${CREATED_RESOURCES[@]}"; do
    case $res in
      "data-lake")
        aws securitylake delete-data-lake || true
        ;;
      "aws-log-source")
        aws securitylake delete-aws-log-source --source-name "aws-log-source-$SUFFIX" || true
        ;;
      "custom-log-source")
        aws securitylake delete-custom-log-source --source-name "custom-log-source-$SUFFIX" || true
        ;;
      *)
        echo "Unknown resource type: $res"
        ;;
    esac
  done
}

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap cleanup_resources EXIT
CREATED_RESOURCES=()

echo "Creating data lake"
aws securitylake create-data-lake --configuration-alias "default" --regions "us-west-2" --tags '{"Environment":"Tutorial","Project":"SecurityLake"}'
CREATED_RESOURCES+=("data-lake")

echo "Verifying data lake creation"
aws securitylake get-data-lake-status --region "us-west-2"

echo "Creating AWS log source"
aws securitylake create-aws-log-source --sources "{'sourceName':'aws-log-source-$SUFFIX','sourceVersion':'1.0','awsLogSourceConfigurations':[{'awsLogTypes':['cloudtrail']}]}"
CREATED_RESOURCES+=("aws-log-source")

echo "Verifying AWS log source creation"
aws securitylake list-log-sources --query "logSources[?sourceName=='aws-log-source-$SUFFIX']" --output text

echo "Creating custom log source"
aws securitylake create-custom-log-source --source-name "custom-log-source-$SUFFIX" --source-version "1.0" --custom-log-types '["custom-log"]'
CREATED_RESOURCES+=("custom-log-source")

echo "Verifying custom log source creation"
aws securitylake list-log-sources --query "logSources[?sourceName=='custom-log-source-$SUFFIX']" --output text

echo "PASS"
