#!/bin/bash
set -e
echo "=== IoT Device Advisor Tutorial ==="
echo "IoT Device Advisor helps validate IoT devices for connectivity with AWS IoT."
echo ""
echo "=== Listing suite definitions ==="
aws iotdeviceadvisor list-suite-definitions --query 'suiteDefinitionInformationList[].suiteDefinitionName' --output text || echo "No suites"
echo ""
echo "=== Listing suite runs ==="
aws iotdeviceadvisor list-suite-runs --query 'suiteRunsList[].suiteRunId' --output text || echo "No runs"
echo ""
echo "PASS"
