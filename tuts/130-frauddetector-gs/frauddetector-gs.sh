#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
VARIABLE_NAME="var_${SUFFIX}"
DETECTOR_ID="det_${SUFFIX}"

# Create a fraud detection variable
VARIABLE_ARN=$(aws frauddetector create-variable \
    --name "${VARIABLE_NAME}" \
    --data-type STRING \
    --data-source EVENT \
    --default-value UNKNOWN \
    --description "Test variable for fraud detection" \
    --query 'variable.arn' --output text)

echo "Variable created: ${VARIABLE_ARN}"

# Clean up variable
aws frauddetector delete-variable --name "${VARIABLE_NAME}" || true

echo "Variable deleted"

# Other CLI commands (example, adjust as needed)
aws frauddetector create-batch-import-job --job-id "job_${SUFFIX}" --input-path "s3://your-bucket/input/" --output-path "s3://your-bucket/output/" --iam-role-arn "arn:aws:iam::123456789012:role/service-role/YourRole" --event-type-name "your-event-type" || true
aws frauddetector create-batch-prediction-job --job-id "pred_${SUFFIX}" --detector-name "your-detector" --detector-version 1 --event-type-name "your-event-type" --output-path "s3://your-bucket/prediction-output/" --iam-role-arn "arn:aws:iam::123456789012:role/service-role/YourRole" || true
aws frauddetector create-detector-version --detector-id "${DETECTOR_ID}" --rules '[{"detectorId":"'${DETECTOR_ID}'","ruleId":"rule_1","ruleVersion":"1"}]' --status DRAFT || true
aws frauddetector create-list --name "list_${SUFFIX}" --elements '["element1","element2"]' || true
aws frauddetector create-model --model-id "model_${SUFFIX}" --model-type ONLINE_FRAUD_INSIGHTS --event-type-name "your-event-type" || true

echo "PASS"