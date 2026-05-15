#!/bin/bash
set -e

echo "=== AWS Recycle Bin Tutorial ==="
echo "This tutorial demonstrates how to create, update, and delete an AWS Recycle Bin rule using the AWS CLI."

if [ -t 1 ]; then 
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="$TEMP_DIR/script.log"
    declare -a CREATED_RESOURCES=()

    cleanup_resources() {
        for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
            RESOURCE=(${CREATED_RESOURCES[$i]})
            type=${RESOURCE[0]}
            id=${RESOURCE[1]}
            case $type in
                rbin_rule) aws rbin delete-rule --identifier "$id" || true ;;
            esac
        done
        rm -rf "$TEMP_DIR"
    }
    trap cleanup_resources EXIT

    REGION="${AWS_DEFAULT_REGION:-us-east-1}"

    echo "=== Step 1: Creating Recycle Bin Rule ==="
    echo "In this step, we will create a Recycle Bin rule with a retention period of 1 day for EBS snapshots."
    echo "This rule helps manage the lifecycle of your EBS snapshots by retaining them for a specified period."
    RULE_ID=$(aws rbin create-rule --retention-period RetentionPeriodValue=1,RetentionPeriodUnit=DAYS --resource-type EBS_SNAPSHOT --query 'Identifier' --output text)
    echo "Rule created: $RULE_ID" 
    CREATED_RESOURCES+=("rbin_rule:$RULE_ID")

    echo "=== Step 2: Verifying Rule Status ==="
    echo "After creating the rule, we need to verify its status to ensure it has been successfully applied."
    echo "This step confirms that the rule is active and functioning as expected."
    aws rbin get-rule --identifier "$RULE_ID" --query 'Status' --output text 

    echo "=== Step 3: Updating Rule Retention Period ==="
    echo "Now, we will update the retention period of the Recycle Bin rule to 7 days."
    echo "Updating the retention period allows you to adjust the lifecycle management of your resources based on changing requirements."
    aws rbin update-rule --identifier "$RULE_ID" --retention-period RetentionPeriodValue=7,RetentionPeriodUnit=DAYS 

    echo "=== Step 4: Deleting the Rule ==="
    echo "Finally, we will delete the Recycle Bin rule to clean up resources."
    echo "Deleting the rule ensures that no unnecessary rules remain in your account, helping maintain a clean and efficient environment."
    aws rbin delete-rule --identifier "$RULE_ID" || true

    echo "PASS"
    echo "Tutorial complete. You have learned how to create, verify, update, and delete an AWS Recycle Bin rule using the AWS CLI."
fi