#!/bin/bash

# AWS WAF Getting Started Script
# This script creates a Web ACL with a string match rule and AWS Managed Rules,
# associates it with a CloudFront distribution, and then cleans up all resources.

set -euo pipefail

# Set up logging
LOG_FILE="waf-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Trap errors and cleanup
trap 'handle_error "Script interrupted"' INT TERM

echo "==================================================="
echo "AWS WAF Getting Started Tutorial"
echo "==================================================="
echo "This script will create AWS WAF resources and associate"
echo "them with a CloudFront distribution."
echo ""

# Maximum number of retries for operations
MAX_RETRIES=3

# Global variables
DISTRIBUTION_ID=""
WEB_ACL_ARN=""
WEB_ACL_ID=""
WEB_ACL_NAME=""
LOCK_TOKEN=""

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Check the log file for details: $LOG_FILE" >&2
    cleanup_resources
    exit 1
}

# Function to validate AWS CLI response using jq
validate_response() {
    local response="$1"
    local error_msg="$2"
    
    if ! command -v jq &> /dev/null; then
        echo "Warning: jq not found. Using basic error checking." >&2
        if echo "$response" | grep -qi "error\|failed"; then
            handle_error "$error_msg: $response"
        fi
        return 0
    fi
    
    if echo "$response" | jq empty 2>/dev/null; then
        if echo "$response" | jq -e '.Error or .Errors or .Message' 2>/dev/null; then
            handle_error "$error_msg: $response"
        fi
    else
        if echo "$response" | grep -qi "error\|failed"; then
            handle_error "$error_msg: $response"
        fi
    fi
}

# Function to safely extract JSON values
extract_json_value() {
    local response="$1"
    local key="$2"
    
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r ".$key // empty" 2>/dev/null || echo ""
    else
        echo "$response" | grep -o "\"$key\": \"[^\"]*" | cut -d'"' -f4 || echo ""
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==================================================="
    echo "CLEANING UP RESOURCES"
    echo "==================================================="
    
    if [ -n "$DISTRIBUTION_ID" ] && [ -n "$WEB_ACL_ARN" ]; then
        echo "Disassociating Web ACL from CloudFront distribution..."
        
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
        if [ -z "$ACCOUNT_ID" ]; then
            echo "Warning: Could not retrieve AWS Account ID"
            return
        fi
        
        DISASSOCIATE_RESULT=$(aws wafv2 disassociate-web-acl \
            --resource-arn "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}" \
            --region us-east-1 2>&1 || echo "")
        
        if echo "$DISASSOCIATE_RESULT" | grep -qi "error"; then
            echo "Warning: Failed to disassociate Web ACL: $DISASSOCIATE_RESULT"
        else
            echo "Web ACL disassociated successfully."
        fi
    fi
    
    if [ -n "$WEB_ACL_ID" ] && [ -n "$WEB_ACL_NAME" ]; then
        echo "Deleting Web ACL..."
        
        GET_RESULT=$(aws wafv2 get-web-acl \
            --name "$WEB_ACL_NAME" \
            --scope CLOUDFRONT \
            --id "$WEB_ACL_ID" \
            --region us-east-1 2>&1 || echo "")
        
        if echo "$GET_RESULT" | grep -qi "error"; then
            echo "Warning: Failed to get Web ACL for deletion: $GET_RESULT"
            echo "You may need to manually delete the Web ACL using the AWS Console."
        else
            LATEST_TOKEN=$(extract_json_value "$GET_RESULT" "LockToken")
            
            if [ -n "$LATEST_TOKEN" ]; then
                DELETE_RESULT=$(aws wafv2 delete-web-acl \
                    --name "$WEB_ACL_NAME" \
                    --scope CLOUDFRONT \
                    --id "$WEB_ACL_ID" \
                    --lock-token "$LATEST_TOKEN" \
                    --region us-east-1 2>&1 || echo "")
                
                if echo "$DELETE_RESULT" | grep -qi "error"; then
                    echo "Warning: Failed to delete Web ACL: $DELETE_RESULT"
                    echo "You may need to manually delete the Web ACL using the AWS Console."
                else
                    echo "Web ACL deleted successfully."
                fi
            else
                echo "Warning: Could not extract lock token for deletion. You may need to manually delete the Web ACL."
            fi
        fi
    fi
    
    echo "Cleanup process completed."
}

# Verify AWS CLI is available and credentials are valid
if ! command -v aws &> /dev/null; then
    handle_error "AWS CLI is not installed or not in PATH"
fi

if ! aws sts get-caller-identity &>/dev/null; then
    handle_error "AWS credentials are not configured or invalid"
fi

# Generate a random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
WEB_ACL_NAME="MyWebACL-${RANDOM_ID}"
METRIC_NAME="MyWebACLMetrics-${RANDOM_ID}"

echo "Using Web ACL name: $WEB_ACL_NAME"

# Step 1: Create a Web ACL
echo ""
echo "==================================================="
echo "STEP 1: Creating Web ACL"
echo "==================================================="

CREATE_RESULT=$(aws wafv2 create-web-acl \
    --name "$WEB_ACL_NAME" \
    --scope "CLOUDFRONT" \
    --default-action Allow={} \
    --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-waf-gs \
    --region us-east-1 2>&1)

validate_response "$CREATE_RESULT" "Failed to create Web ACL"

WEB_ACL_ID=$(extract_json_value "$CREATE_RESULT" "Summary.Id")
WEB_ACL_ARN=$(extract_json_value "$CREATE_RESULT" "Summary.ARN")
LOCK_TOKEN=$(extract_json_value "$CREATE_RESULT" "Summary.LockToken")

if [ -z "$WEB_ACL_ID" ]; then
    handle_error "Failed to extract Web ACL ID from response"
fi

if [ -z "$LOCK_TOKEN" ]; then
    handle_error "Failed to extract Lock Token from response"
fi

echo "Web ACL created successfully with ID: $WEB_ACL_ID"
echo "Lock Token: $LOCK_TOKEN (truncated for security)"

# Step 2: Add a String Match Rule
echo ""
echo "==================================================="
echo "STEP 2: Adding String Match Rule"
echo "==================================================="

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Attempt $i to add string match rule..."
    
    GET_RESULT=$(aws wafv2 get-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope CLOUDFRONT \
        --id "$WEB_ACL_ID" \
        --region us-east-1 2>&1 || echo "")
    
    if echo "$GET_RESULT" | grep -qi "error"; then
        echo "Warning: Failed to get Web ACL for update: $GET_RESULT"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to get Web ACL after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    LATEST_TOKEN=$(extract_json_value "$GET_RESULT" "WebACL.LockToken")
    
    if [ -z "$LATEST_TOKEN" ]; then
        echo "Warning: Could not extract lock token for update"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to extract lock token after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    echo "Updating Web ACL with string match rule..."
    
    UPDATE_RESULT=$(aws wafv2 update-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope "CLOUDFRONT" \
        --id "$WEB_ACL_ID" \
        --lock-token "$LATEST_TOKEN" \
        --default-action Allow={} \
        --rules '[{
            "Name": "UserAgentRule",
            "Priority": 0,
            "Statement": {
                "ByteMatchStatement": {
                    "SearchString": "MyAgent",
                    "FieldToMatch": {
                        "SingleHeader": {
                            "Name": "user-agent"
                        }
                    },
                    "TextTransformations": [
                        {
                            "Priority": 0,
                            "Type": "NONE"
                        }
                    ],
                    "PositionalConstraint": "EXACTLY"
                }
            },
            "Action": {
                "Count": {}
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "UserAgentRuleMetric"
            }
        }]' \
        --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME" \
        --region us-east-1 2>&1 || echo "")
    
    if echo "$UPDATE_RESULT" | grep -qi "WAFOptimisticLockException"; then
        echo "Optimistic lock exception encountered. Will retry with new lock token."
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to add string match rule after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    elif echo "$UPDATE_RESULT" | grep -qi "error"; then
        handle_error "Failed to add string match rule: $UPDATE_RESULT"
    else
        echo "String match rule added successfully."
        break
    fi
done

# Step 3: Add AWS Managed Rules
echo ""
echo "==================================================="
echo "STEP 3: Adding AWS Managed Rules"
echo "==================================================="

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Attempt $i to add AWS Managed Rules..."
    
    GET_RESULT=$(aws wafv2 get-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope CLOUDFRONT \
        --id "$WEB_ACL_ID" \
        --region us-east-1 2>&1 || echo "")
    
    if echo "$GET_RESULT" | grep -qi "error"; then
        echo "Warning: Failed to get Web ACL for update: $GET_RESULT"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to get Web ACL after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    LATEST_TOKEN=$(extract_json_value "$GET_RESULT" "WebACL.LockToken")
    
    if [ -z "$LATEST_TOKEN" ]; then
        echo "Warning: Could not extract lock token for update"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to extract lock token after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    echo "Updating Web ACL with AWS Managed Rules..."
    
    UPDATE_RESULT=$(aws wafv2 update-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope "CLOUDFRONT" \
        --id "$WEB_ACL_ID" \
        --lock-token "$LATEST_TOKEN" \
        --default-action Allow={} \
        --rules '[{
            "Name": "UserAgentRule",
            "Priority": 0,
            "Statement": {
                "ByteMatchStatement": {
                    "SearchString": "MyAgent",
                    "FieldToMatch": {
                        "SingleHeader": {
                            "Name": "user-agent"
                        }
                    },
                    "TextTransformations": [
                        {
                            "Priority": 0,
                            "Type": "NONE"
                        }
                    ],
                    "PositionalConstraint": "EXACTLY"
                }
            },
            "Action": {
                "Count": {}
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "UserAgentRuleMetric"
            }
        },
        {
            "Name": "AWS-AWSManagedRulesCommonRuleSet",
            "Priority": 1,
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesCommonRuleSet",
                    "ExcludedRules": []
                }
            },
            "OverrideAction": {
                "Count": {}
            },
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "AWS-AWSManagedRulesCommonRuleSet"
            }
        }]' \
        --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME" \
        --region us-east-1 2>&1 || echo "")
    
    if echo "$UPDATE_RESULT" | grep -qi "WAFOptimisticLockException"; then
        echo "Optimistic lock exception encountered. Will retry with new lock token."
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to add AWS Managed Rules after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    elif echo "$UPDATE_RESULT" | grep -qi "error"; then
        handle_error "Failed to add AWS Managed Rules: $UPDATE_RESULT"
    else
        echo "AWS Managed Rules added successfully."
        break
    fi
done

# Step 4: List CloudFront distributions
echo ""
echo "==================================================="
echo "STEP 4: Listing CloudFront Distributions"
echo "==================================================="

CF_RESULT=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,DomainName:DomainName}" --output table 2>&1 || echo "")
if echo "$CF_RESULT" | grep -qi "error"; then
    echo "Warning: Failed to list CloudFront distributions: $CF_RESULT"
    echo "Continuing without CloudFront association."
else
    echo "$CF_RESULT"

    echo ""
    echo "==================================================="
    echo "STEP 5: Associate Web ACL with CloudFront Distribution"
    echo "==================================================="
    echo "Enter the ID of the CloudFront distribution to associate with the Web ACL:"
    echo "(If you don't have a CloudFront distribution, press Enter to skip this step)"
    read -r DISTRIBUTION_ID

    if [ -n "$DISTRIBUTION_ID" ]; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
        if [ -z "$ACCOUNT_ID" ]; then
            echo "Warning: Could not retrieve AWS Account ID"
            DISTRIBUTION_ID=""
        else
            ASSOCIATE_RESULT=$(aws wafv2 associate-web-acl \
                --web-acl-arn "$WEB_ACL_ARN" \
                --resource-arn "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}" \
                --region us-east-1 2>&1 || echo "")
            
            if echo "$ASSOCIATE_RESULT" | grep -qi "error"; then
                echo "Warning: Failed to associate Web ACL with CloudFront distribution: $ASSOCIATE_RESULT"
                echo "Continuing without CloudFront association."
                DISTRIBUTION_ID=""
            else
                echo "Web ACL associated with CloudFront distribution successfully."
            fi
        fi
    else
        echo "Skipping association with CloudFront distribution."
    fi
fi

# Display summary of created resources
echo ""
echo "==================================================="
echo "RESOURCE SUMMARY"
echo "==================================================="
echo "Web ACL Name: $WEB_ACL_NAME"
echo "Web ACL ID: $WEB_ACL_ID"
echo "Web ACL ARN: $WEB_ACL_ARN"
if [ -n "$DISTRIBUTION_ID" ]; then
    echo "Associated CloudFront Distribution: $DISTRIBUTION_ID"
fi
echo ""

# Ask user if they want to clean up resources
echo "==================================================="
echo "CLEANUP CONFIRMATION"
echo "==================================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    cleanup_resources
else
    echo ""
    echo "Resources have NOT been cleaned up. You can manually clean them up later."
    echo "To clean up resources manually, run the following commands:"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "<ACCOUNT_ID>")
    
    if [ -n "$DISTRIBUTION_ID" ]; then
        echo "aws wafv2 disassociate-web-acl --resource-arn \"arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}\" --region us-east-1"
    fi
    echo "aws wafv2 delete-web-acl --name \"$WEB_ACL_NAME\" --scope CLOUDFRONT --id \"$WEB_ACL_ID\" --lock-token \"<get-latest-token>\" --region us-east-1"
    echo ""
    echo "To get the latest lock token, run:"
    echo "aws wafv2 get-web-acl --name \"$WEB_ACL_NAME\" --scope CLOUDFRONT --id \"$WEB_ACL_ID\" --region us-east-1"
fi

echo ""
echo "==================================================="
echo "Tutorial completed!"
echo "==================================================="
echo "Log file: $LOG_FILE"