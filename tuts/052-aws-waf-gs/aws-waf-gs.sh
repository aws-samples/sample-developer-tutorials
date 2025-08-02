#!/bin/bash

# AWS WAF Getting Started Script
# This script creates a Web ACL with a string match rule and AWS Managed Rules,
# associates it with a CloudFront distribution, and then cleans up all resources.

# Set up logging
LOG_FILE="waf-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "AWS WAF Getting Started Tutorial"
echo "==================================================="
echo "This script will create AWS WAF resources and associate"
echo "them with a CloudFront distribution."
echo ""

# Maximum number of retries for operations
MAX_RETRIES=3

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Check the log file for details: $LOG_FILE"
    cleanup_resources
    exit 1
}

# Function to check command success
check_command() {
    if echo "$1" | grep -i "error" > /dev/null; then
        handle_error "$2: $1"
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
        DISASSOCIATE_RESULT=$(aws wafv2 disassociate-web-acl \
            --resource-arn "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DISTRIBUTION_ID" \
            --region us-east-1 2>&1)
        
        if echo "$DISASSOCIATE_RESULT" | grep -i "error" > /dev/null; then
            echo "Warning: Failed to disassociate Web ACL: $DISASSOCIATE_RESULT"
        else
            echo "Web ACL disassociated successfully."
        fi
    fi
    
    if [ -n "$WEB_ACL_ID" ] && [ -n "$WEB_ACL_NAME" ]; then
        echo "Deleting Web ACL..."
        
        # Get the latest lock token before deletion
        GET_RESULT=$(aws wafv2 get-web-acl \
            --name "$WEB_ACL_NAME" \
            --scope CLOUDFRONT \
            --id "$WEB_ACL_ID" \
            --region us-east-1 2>&1)
        
        if echo "$GET_RESULT" | grep -i "error" > /dev/null; then
            echo "Warning: Failed to get Web ACL for deletion: $GET_RESULT"
            echo "You may need to manually delete the Web ACL using the AWS Console."
        else
            LATEST_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
            
            if [ -n "$LATEST_TOKEN" ]; then
                DELETE_RESULT=$(aws wafv2 delete-web-acl \
                    --name "$WEB_ACL_NAME" \
                    --scope CLOUDFRONT \
                    --id "$WEB_ACL_ID" \
                    --lock-token "$LATEST_TOKEN" \
                    --region us-east-1 2>&1)
                
                if echo "$DELETE_RESULT" | grep -i "error" > /dev/null; then
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
    --region us-east-1 2>&1)

check_command "$CREATE_RESULT" "Failed to create Web ACL"

# Extract Web ACL ID, ARN, and Lock Token from the Summary object
WEB_ACL_ID=$(echo "$CREATE_RESULT" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)
WEB_ACL_ARN=$(echo "$CREATE_RESULT" | grep -o '"ARN": "[^"]*' | cut -d'"' -f4)
LOCK_TOKEN=$(echo "$CREATE_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)

if [ -z "$WEB_ACL_ID" ]; then
    handle_error "Failed to extract Web ACL ID"
fi

if [ -z "$LOCK_TOKEN" ]; then
    handle_error "Failed to extract Lock Token"
fi

echo "Web ACL created successfully with ID: $WEB_ACL_ID"
echo "Lock Token: $LOCK_TOKEN"

# Step 2: Add a String Match Rule
echo ""
echo "==================================================="
echo "STEP 2: Adding String Match Rule"
echo "==================================================="

# Try to update with retries
for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Attempt $i to add string match rule..."
    
    # Get the latest lock token before updating
    GET_RESULT=$(aws wafv2 get-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope CLOUDFRONT \
        --id "$WEB_ACL_ID" \
        --region us-east-1 2>&1)
    
    if echo "$GET_RESULT" | grep -i "error" > /dev/null; then
        echo "Warning: Failed to get Web ACL for update: $GET_RESULT"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to get Web ACL after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    LATEST_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
    
    if [ -z "$LATEST_TOKEN" ]; then
        echo "Warning: Could not extract lock token for update"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to extract lock token after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    echo "Using lock token: $LATEST_TOKEN"
    
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
        --region us-east-1 2>&1)
    
    if echo "$UPDATE_RESULT" | grep -i "WAFOptimisticLockException" > /dev/null; then
        echo "Optimistic lock exception encountered. Will retry with new lock token."
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to add string match rule after $MAX_RETRIES attempts: $UPDATE_RESULT"
        fi
        sleep 2
        continue
    elif echo "$UPDATE_RESULT" | grep -i "error" > /dev/null; then
        handle_error "Failed to add string match rule: $UPDATE_RESULT"
    else
        # Success
        echo "String match rule added successfully."
        break
    fi
done

# Step 3: Add AWS Managed Rules
echo ""
echo "==================================================="
echo "STEP 3: Adding AWS Managed Rules"
echo "==================================================="

# Try to update with retries
for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Attempt $i to add AWS Managed Rules..."
    
    # Get the latest lock token before updating
    GET_RESULT=$(aws wafv2 get-web-acl \
        --name "$WEB_ACL_NAME" \
        --scope CLOUDFRONT \
        --id "$WEB_ACL_ID" \
        --region us-east-1 2>&1)
    
    if echo "$GET_RESULT" | grep -i "error" > /dev/null; then
        echo "Warning: Failed to get Web ACL for update: $GET_RESULT"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to get Web ACL after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    LATEST_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
    
    if [ -z "$LATEST_TOKEN" ]; then
        echo "Warning: Could not extract lock token for update"
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to extract lock token after $MAX_RETRIES attempts"
        fi
        sleep 2
        continue
    fi
    
    echo "Using lock token: $LATEST_TOKEN"
    
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
        --region us-east-1 2>&1)
    
    if echo "$UPDATE_RESULT" | grep -i "WAFOptimisticLockException" > /dev/null; then
        echo "Optimistic lock exception encountered. Will retry with new lock token."
        if [ "$i" -eq "$MAX_RETRIES" ]; then
            handle_error "Failed to add AWS Managed Rules after $MAX_RETRIES attempts: $UPDATE_RESULT"
        fi
        sleep 2
        continue
    elif echo "$UPDATE_RESULT" | grep -i "error" > /dev/null; then
        handle_error "Failed to add AWS Managed Rules: $UPDATE_RESULT"
    else
        # Success
        echo "AWS Managed Rules added successfully."
        break
    fi
done

# Step 4: List CloudFront distributions
echo ""
echo "==================================================="
echo "STEP 4: Listing CloudFront Distributions"
echo "==================================================="

CF_RESULT=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,DomainName:DomainName}" --output table 2>&1)
if echo "$CF_RESULT" | grep -i "error" > /dev/null; then
    echo "Warning: Failed to list CloudFront distributions: $CF_RESULT"
    echo "Continuing without CloudFront association."
else
    echo "$CF_RESULT"

    # Ask user to select a CloudFront distribution
    echo ""
    echo "==================================================="
    echo "STEP 5: Associate Web ACL with CloudFront Distribution"
    echo "==================================================="
    echo "Enter the ID of the CloudFront distribution to associate with the Web ACL:"
    echo "(If you don't have a CloudFront distribution, press Enter to skip this step)"
    read -r DISTRIBUTION_ID

    if [ -n "$DISTRIBUTION_ID" ]; then
        ASSOCIATE_RESULT=$(aws wafv2 associate-web-acl \
            --web-acl-arn "$WEB_ACL_ARN" \
            --resource-arn "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DISTRIBUTION_ID" \
            --region us-east-1 2>&1)
        
        if echo "$ASSOCIATE_RESULT" | grep -i "error" > /dev/null; then
            echo "Warning: Failed to associate Web ACL with CloudFront distribution: $ASSOCIATE_RESULT"
            echo "Continuing without CloudFront association."
            DISTRIBUTION_ID=""
        else
            echo "Web ACL associated with CloudFront distribution successfully."
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

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    cleanup_resources
else
    echo ""
    echo "Resources have NOT been cleaned up. You can manually clean them up later."
    echo "To clean up resources manually, run the following commands:"
    if [ -n "$DISTRIBUTION_ID" ]; then
        echo "aws wafv2 disassociate-web-acl --resource-arn \"arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DISTRIBUTION_ID\" --region us-east-1"
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
