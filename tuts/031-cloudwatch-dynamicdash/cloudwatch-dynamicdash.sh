#!/bin/bash

# Script to create a CloudWatch dashboard with Lambda function name as a variable
# This script creates a CloudWatch dashboard that allows you to switch between different Lambda functions

set -euo pipefail

# Set up logging
LOG_FILE="cloudwatch-dashboard-script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting CloudWatch dashboard creation script"

# Trap errors and cleanup
CLEANUP_RESOURCES=()
trap 'cleanup_on_error' ERR

cleanup_on_error() {
    local line_number=$1
    echo "ERROR: Script failed at line $line_number"
    echo "Attempting cleanup of partially created resources..."
    cleanup_resources
    exit 1
}

# Function to safely cleanup resources
cleanup_resources() {
    local exit_code=0
    
    # Delete dashboard if it exists
    if aws cloudwatch get-dashboard --dashboard-name LambdaMetricsDashboard &>/dev/null; then
        echo "Deleting CloudWatch dashboard..."
        aws cloudwatch delete-dashboards --dashboard-names LambdaMetricsDashboard || exit_code=1
    fi
    
    # Delete Lambda function if created
    if [ -n "${FUNCTION_NAME:-}" ] && aws lambda get-function --function-name "$FUNCTION_NAME" &>/dev/null; then
        echo "Deleting Lambda function..."
        aws lambda delete-function --function-name "$FUNCTION_NAME" || exit_code=1
    fi
    
    # Detach and delete IAM role if created
    if [ -n "${ROLE_NAME:-}" ]; then
        echo "Detaching role policy..."
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null || true
        
        echo "Deleting IAM role..."
        aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || exit_code=1
    fi
    
    # Cleanup temporary files
    rm -f dashboard-body.json
    
    return $exit_code
}

# Function to handle user-requested cleanup
handle_cleanup_request() {
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "Resources created:"
    echo "- CloudWatch Dashboard: LambdaMetricsDashboard"
    if [ -n "${FUNCTION_NAME:-}" ]; then
        echo "- Lambda Function: $FUNCTION_NAME"
        echo "- IAM Role: $ROLE_NAME"
    fi
    echo ""
    echo -n "Do you want to clean up all created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
        echo "Cleaning up resources..."
        cleanup_resources
        echo "Cleanup complete."
    else
        echo "Resources were not cleaned up. You can manually delete them later with:"
        echo "aws cloudwatch delete-dashboards --dashboard-names LambdaMetricsDashboard"
        if [ -n "${FUNCTION_NAME:-}" ]; then
            echo "aws lambda delete-function --function-name $FUNCTION_NAME"
            echo "aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
            echo "aws iam delete-role --role-name $ROLE_NAME"
        fi
    fi
}

# Validate input parameters
validate_input() {
    if [ -z "${1:-}" ]; then
        return 1
    fi
    return 0
}

# Function to safely execute AWS CLI commands
execute_aws_command() {
    local command=("$@")
    local output
    
    if output=$("${command[@]}" 2>&1); then
        echo "$output"
        return 0
    else
        echo "ERROR: Failed to execute: ${command[*]}" >&2
        return 1
    fi
}

# Check if AWS CLI is installed and configured
echo "Checking AWS CLI configuration..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "ERROR: AWS CLI is not properly configured. Please configure it with 'aws configure' and try again."
    exit 1
fi

# Display AWS account information
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# Get the current region
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-1"
    echo "No region found in AWS config, defaulting to $REGION"
fi
echo "Using region: $REGION"

# Validate region is not empty
if ! validate_input "$REGION"; then
    echo "ERROR: Unable to determine AWS region"
    exit 1
fi

# Check if there are any Lambda functions in the account
echo "Checking for Lambda functions..."
LAMBDA_FUNCTIONS=$(aws lambda list-functions --region "$REGION" --query "Functions[*].FunctionName" --output text)

if [ -z "$LAMBDA_FUNCTIONS" ]; then
    echo "No Lambda functions found in your account. Creating a simple test function..."
    
    # Create a temporary directory for Lambda function code
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    # Create a simple Lambda function
    cat > "$TEMP_DIR/index.js" << 'LAMBDA_EOF'
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    return {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!'),
    };
};
LAMBDA_EOF
    
    # Zip the function code
    if ! (cd "$TEMP_DIR" && zip -q function.zip index.js); then
        echo "ERROR: Failed to create function zip file"
        exit 1
    fi
    
    # Create a role for the Lambda function with specific naming to avoid conflicts
    ROLE_NAME="LambdaDashboardTestRole-$(date +%s)"
    
    echo "Creating IAM role: $ROLE_NAME"
    ROLE_ARN=$(aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
        --query "Role.Arn" \
        --output text)
    
    # Tag the role
    aws iam tag-role \
        --role-name "$ROLE_NAME" \
        --tags "Key=project,Value=doc-smith" "Key=tutorial,Value=cloudwatch-dynamicdash"
    
    echo "Waiting for role to be available..."
    sleep 3
    
    # Attach basic Lambda execution policy
    echo "Attaching execution policy to role..."
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    
    sleep 3
    
    # Create the Lambda function
    FUNCTION_NAME="DashboardTestFunction-$(date +%s)"
    echo "Creating Lambda function: $FUNCTION_NAME"
    
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime "nodejs18.x" \
        --role "$ROLE_ARN" \
        --handler "index.handler" \
        --zip-file "fileb://$TEMP_DIR/function.zip" \
        --region "$REGION" \
        --tags "project=doc-smith,tutorial=cloudwatch-dynamicdash" > /dev/null
    
    # Invoke the function to generate some metrics
    echo "Invoking Lambda function to generate metrics..."
    for i in {1..5}; do
        aws lambda invoke \
            --function-name "$FUNCTION_NAME" \
            --region "$REGION" \
            --payload '{}' \
            /dev/null > /dev/null 2>&1 || true
        sleep 1
    done
    
    # Set the function name for the dashboard
    DEFAULT_FUNCTION="$FUNCTION_NAME"
else
    # Use the first Lambda function as default
    DEFAULT_FUNCTION=$(echo "$LAMBDA_FUNCTIONS" | awk '{print $1}')
    echo "Found Lambda functions. Using $DEFAULT_FUNCTION as default."
fi

# Escape function name for JSON
DEFAULT_FUNCTION_ESCAPED=$(printf '%s\n' "$DEFAULT_FUNCTION" | sed 's/[&/\]/\\&/g')

# Create a dashboard with Lambda metrics and a function name variable
echo "Creating CloudWatch dashboard with Lambda function name variable..."

# Create a JSON file for the dashboard body
cat > dashboard-body.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", "FunctionName", "\${FunctionName}" ],
          [ ".", "Errors", ".", "." ],
          [ ".", "Throttles", ".", "." ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$REGION",
        "title": "Lambda Function Metrics for \${FunctionName}",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Duration", "FunctionName", "\${FunctionName}", { "stat": "Average" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$REGION",
        "title": "Duration for \${FunctionName}",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "ConcurrentExecutions", "FunctionName", "\${FunctionName}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$REGION",
        "title": "Concurrent Executions for \${FunctionName}",
        "period": 300
      }
    }
  ],
  "periodOverride": "auto",
  "variables": [
    {
      "type": "property",
      "id": "FunctionName",
      "property": "FunctionName",
      "label": "Lambda Function",
      "inputType": "select",
      "values": [
        {
          "value": "$DEFAULT_FUNCTION_ESCAPED",
          "label": "$DEFAULT_FUNCTION_ESCAPED"
        }
      ]
    }
  ]
}
EOF

# Validate JSON syntax before creating dashboard
if ! jq empty dashboard-body.json 2>/dev/null; then
    echo "ERROR: Generated invalid dashboard JSON"
    rm -f dashboard-body.json
    exit 1
fi

# Create the dashboard using the JSON file
echo "Deploying dashboard..."
aws cloudwatch put-dashboard \
    --dashboard-name "LambdaMetricsDashboard" \
    --dashboard-body file://dashboard-body.json \
    --region "$REGION" > /dev/null

# Tag the dashboard
echo "Tagging dashboard..."
DASHBOARD_ARN=$(aws cloudwatch list-dashboards \
    --region "$REGION" \
    --query "DashboardEntries[?DashboardName=='LambdaMetricsDashboard'].DashboardArn" \
    --output text)

if [ -n "$DASHBOARD_ARN" ]; then
    aws cloudwatch tag-resource \
        --resource-arn "$DASHBOARD_ARN" \
        --tags "Key=project,Value=doc-smith" "Key=tutorial,Value=cloudwatch-dynamicdash"
fi

# Verify the dashboard was created
echo "Verifying dashboard creation..."
if ! aws cloudwatch get-dashboard \
    --dashboard-name "LambdaMetricsDashboard" \
    --region "$REGION" > /dev/null 2>&1; then
    echo "ERROR: Failed to verify dashboard creation"
    cleanup_resources
    exit 1
fi

echo "Dashboard verification successful!"

# List all dashboards to confirm
echo "Listing all dashboards:"
aws cloudwatch list-dashboards --region "$REGION" --output table

# Show instructions for accessing the dashboard
echo ""
echo "=========================================="
echo "Dashboard created successfully!"
echo "=========================================="
echo "To access your dashboard:"
echo "1. Open the CloudWatch console at https://console.aws.amazon.com/cloudwatch/"
echo "2. In the navigation pane, choose Dashboards"
echo "3. Select LambdaMetricsDashboard"
echo "4. Use the 'Lambda Function' dropdown at the top to select different Lambda functions"
echo ""

# Prompt for cleanup
handle_cleanup_request

echo "Script completed successfully!"