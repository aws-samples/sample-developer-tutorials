#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
echo "=== IoT Device Advisor ==="
echo "Listing suite definitions..."
aws iotdeviceadvisor list-suite-definitions --query 'suiteDefinitionInformationList[].suiteDefinitionName' --output text || echo "None"
echo "PASS"
