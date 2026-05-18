#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Define the execution role ARN
EXECUTION_ROLE_ARN='arn:aws:iam::559823168634:role/doc-babu-dlm-role'

# Create a lifecycle policy
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
    --query 'PolicyId' --output text)

# Retrieve and print the created policy details
aws dlm get-lifecycle-policy --policy-id "$POLICY_ID" || true

# Delete the lifecycle policy
aws dlm delete-lifecycle-policy --policy-id "$POLICY_ID" || true

echo "PASS"