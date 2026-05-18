#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()
cleanup_resources() {
  for ARN in "${CREATED_RESOURCES[@]}"; do
    aws iotdeviceadvisor delete-suite-definition --suite-definition-id "$ARN" || true
  done
  rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== IoT Device Advisor Tutorial ==="
echo "IoT Device Advisor helps validate IoT devices for connectivity with AWS IoT."

echo ""
echo "=== Listing suite definitions ==="
aws iotdeviceadvisor list-suite-definitions --query'suiteDefinitionInformationList[].suiteDefinitionName' --output text || echo "No suites"

echo ""
echo "=== Creating a suite definition ==="
SUITE_DEFINITION_NAME="doc-smith-$SUFFIX"
ARN=$(aws iotdeviceadvisor create-suite-definition --suite-definition-configuration '{"suiteDefinitionName":"'"$SUITE_DEFINITION_NAME"',"tags":{"project":"doc-smith","tutorial":"iotdeviceadvisor-gs"}}' --query'suiteDefinitionConfiguration.suiteDefinitionArn' --output text)
CREATED_RESOURCES+=("$ARN")

echo ""
echo "=== Listing suite runs ==="
aws iotdeviceadvisor list-suite-runs --query'suiteRunsList[].suiteRunId' --output text || echo "No runs"

echo ""
echo "PASS"
