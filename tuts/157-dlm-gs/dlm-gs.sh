#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws dlm delete-lifecycle-policy --policy-id "$ARN" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

# Step 1: Create execution role ARN
EXECUTION_ROLE_ARN='arn:aws:iam::559823168634:role/doc-babu-dlm-role'

# Step 2: Create lifecycle policy
POLICY_ID=$(aws dlm create-lifecycle-policy \
    --execution-role-arn "$EXECUTION_ROLE_ARN" \
    --description "Test policy $SUFFIX" \
    --state ENABLED \
    --policy-details '{
        "PolicyType": "EBS_SNAPSHOT_MANAGEMENT",
        "ResourceTypes": ["VOLUME"],
        "Schedules": [{
            "Name": "Daily",
            "CreateRule": {
                "Interval": 24,
                "IntervalUnit": "HOURS"
            },
            "RetainRule": {
                "Count": 1
            }
        }],
        "TargetTags": [{"Key": "Backup", "Value": "true"}]
    }' \
    --tags Key=project,Value=doc-smith \
    --query 'PolicyId' --output text)
CREATED_RESOURCES+=("$POLICY_ID")

# Step 3: Retrieve and print the created policy details
aws dlm get-lifecycle-policy --policy-id "$POLICY_ID" >> "$LOG_FILE" 2>&1

echo "PASS"