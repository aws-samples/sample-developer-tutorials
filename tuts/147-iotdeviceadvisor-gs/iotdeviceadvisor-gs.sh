#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
SUITE_DEFINITION_CONFIGURATION='{
    "suiteDefinitionName": "TestSuite'"$SUFFIX"'",
    "devices": [
        {
            "thingArn": "arn:aws:iot:us-east-1:123456789012:thing/MyTestThing",
            "certificateArn": "arn:aws:iot:us-east-1:123456789012:cert/12345678901234567890123456789012345"
        }
    ],
    "intendedForQualification": false,
    "isLongDurationTest": false,
    "protocol": "Mqtt",
    "devicePermissionRoleArn": "arn:aws:iam::559823168634:role/doc-babu-iotdeviceadvisor-role"
}'

SUITE_DEFINITION_ID=$(aws iotdeviceadvisor create-suite-definition --suite-definition-configuration "$SUITE_DEFINITION_CONFIGURATION" --query'suiteDefinitionId' --output text)

echo "Suite Definition created with ID: $SUITE_DEFINITION_ID"

SUITE_DEFINITION_RESPONSE=$(aws iotdeviceadvisor get-suite-definition --suite-definition-id "$SUITE_DEFINITION_ID" --query 'suiteDefinitionConfiguration' --output text)
echo "Suite Definition retrieved: $SUITE_DEFINITION_RESPONSE"

SUITE_DEFINITIONS_LIST=$(aws iotdeviceadvisor list-suite-definitions --query'suiteDefinitionConfigurations' --output text)
echo "List of Suite Definitions: $SUITE_DEFINITIONS_LIST"

SUITE_RUN_ID=$(aws iotdeviceadvisor create-suite-run --suite-definition-id "$SUITE_DEFINITION_ID" --query 'suiteRunId' --output text)
echo "Suite Run created with ID: $SUITE_RUN_ID"

SUITE_RUN_RESPONSE=$(aws iotdeviceadvisor get-suite-run --suite-definition-id "$SUITE_DEFINITION_ID" --suite-run-id "$SUITE_RUN_ID" --query 'suiteRunConfiguration' --output text)
echo "Suite Run retrieved: $SUITE_RUN_RESPONSE"

SUITE_RUNS_LIST=$(aws iotdeviceadvisor list-suite-runs --suite-definition-id "$SUITE_DEFINITION_ID" --query 'suiteRuns' --output text)
echo "List of Suite Runs: $SUITE_RUNS_LIST"

SUITE_RUN_REPORT=$(aws iotdeviceadvisor get-suite-run-report --suite-definition-id "$SUITE_DEFINITION_ID" --suite-run-id "$SUITE_RUN_ID" --query 'testResults' --output text)
echo "Suite Run Report: $SUITE_RUN_REPORT"

aws iotdeviceadvisor delete-suite-definition --suite-definition-id "$SUITE_DEFINITION_ID" || true
echo "Suite Definition with ID $SUITE_DEFINITION_ID deleted"

echo "PASS"