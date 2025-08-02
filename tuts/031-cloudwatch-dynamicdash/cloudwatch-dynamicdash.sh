#!/bin/bash

# Script to create a CloudWatch dashboard with Lambda function name as a variable
# This script creates a CloudWatch dashboard that allows you to switch between different Lambda functions

# Set up logging
LOG_FILE="cloudwatch-dashboard-script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date): Starting CloudWatch dashboard creation script"

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Resources created:"
    echo "- CloudWatch Dashboard: LambdaMetricsDashboard"
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "An error occurred. Do you want to clean up the created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
        echo "Cleaning up resources..."
        aws cloudwatch delete-dashboards --dashboard-names LambdaMetricsDashboard
        echo "Cleanup complete."
    else
        echo "Resources were not cleaned up. You can manually delete them later."
    fi
    exit 1
}

# Check if AWS CLI is installed and configured
echo "Checking AWS CLI configuration..."
aws sts get-caller-identity > /dev/null 2>&1
if [ $? -ne 0 ]; then
    handle_error "AWS CLI is not properly configured. Please configure it with 'aws configure' and try again."
fi

# Get the current region
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-1"
    echo "No region found in AWS config, defaulting to $REGION"
fi
echo "Using region: $REGION"

# Check if there are any Lambda functions in the account
echo "Checking for Lambda functions..."
LAMBDA_FUNCTIONS=$(aws lambda list-functions --query "Functions[*].FunctionName" --output text)
if [ -z "$LAMBDA_FUNCTIONS" ]; then
    echo "No Lambda functions found in your account. Creating a simple test function..."
    
    # Create a temporary directory for Lambda function code
    TEMP_DIR=$(mktemp -d)
    
    # Create a simple Lambda function
    cat > "$TEMP_DIR/index.js" << EOF
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    return {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!'),
    };
};
EOF
    
    # Zip the function code
    cd "$TEMP_DIR" || handle_error "Failed to change to temporary directory"
    zip -q function.zip index.js
    
    # Create a role for the Lambda function
    ROLE_NAME="LambdaDashboardTestRole"
    ROLE_ARN=$(aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
        --query "Role.Arn" \
        --output text)
    
    if [ $? -ne 0 ]; then
        handle_error "Failed to create IAM role for Lambda function"
    fi
    
    echo "Waiting for role to be available..."
    sleep 10
    
    # Attach basic Lambda execution policy
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    
    if [ $? -ne 0 ]; then
        aws iam delete-role --role-name "$ROLE_NAME"
        handle_error "Failed to attach policy to IAM role"
    fi
    
    # Create the Lambda function
    FUNCTION_NAME="DashboardTestFunction"
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip
    
    if [ $? -ne 0 ]; then
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        aws iam delete-role --role-name "$ROLE_NAME"
        handle_error "Failed to create Lambda function"
    fi
    
    # Invoke the function to generate some metrics
    echo "Invoking Lambda function to generate metrics..."
    for i in {1..5}; do
        aws lambda invoke --function-name "$FUNCTION_NAME" --payload '{}' /dev/null > /dev/null
        sleep 1
    done
    
    # Clean up temporary directory
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    # Set the function name for the dashboard
    DEFAULT_FUNCTION="$FUNCTION_NAME"
else
    # Use the first Lambda function as default
    DEFAULT_FUNCTION=$(echo "$LAMBDA_FUNCTIONS" | awk '{print $1}')
    echo "Found Lambda functions. Using $DEFAULT_FUNCTION as default."
fi

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
          "value": "$DEFAULT_FUNCTION",
          "label": "$DEFAULT_FUNCTION"
        }
      ]
    }
  ]
}
EOF

# Create the dashboard using the JSON file
DASHBOARD_RESULT=$(aws cloudwatch put-dashboard --dashboard-name LambdaMetricsDashboard --dashboard-body file://dashboard-body.json)
DASHBOARD_EXIT_CODE=$?

# Check if there was a fatal error
if [ $DASHBOARD_EXIT_CODE -ne 0 ]; then
    # If we created resources, clean them up
    if [ -n "${FUNCTION_NAME:-}" ]; then
        aws lambda delete-function --function-name "$FUNCTION_NAME"
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        aws iam delete-role --role-name "$ROLE_NAME"
    fi
    handle_error "Failed to create CloudWatch dashboard."
fi

# Display any validation messages but continue
if [[ "$DASHBOARD_RESULT" == *"DashboardValidationMessages"* ]]; then
    echo "Dashboard created with validation messages:"
    echo "$DASHBOARD_RESULT"
    echo "These validation messages are warnings and the dashboard should still function."
else
    echo "Dashboard created successfully!"
fi

# Verify the dashboard was created
echo "Verifying dashboard creation..."
DASHBOARD_INFO=$(aws cloudwatch get-dashboard --dashboard-name LambdaMetricsDashboard)
DASHBOARD_INFO_EXIT_CODE=$?

if [ $DASHBOARD_INFO_EXIT_CODE -ne 0 ]; then
    # If we created resources, clean them up
    if [ -n "${FUNCTION_NAME:-}" ]; then
        aws lambda delete-function --function-name "$FUNCTION_NAME"
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        aws iam delete-role --role-name "$ROLE_NAME"
    fi
    handle_error "Failed to verify dashboard creation."
fi

echo "Dashboard verification successful!"
echo "Dashboard details:"
echo "$DASHBOARD_INFO"

# List all dashboards to confirm
echo "Listing all dashboards:"
DASHBOARDS=$(aws cloudwatch list-dashboards)
DASHBOARDS_EXIT_CODE=$?

if [ $DASHBOARDS_EXIT_CODE -ne 0 ]; then
    # If we created resources, clean them up
    if [ -n "${FUNCTION_NAME:-}" ]; then
        aws lambda delete-function --function-name "$FUNCTION_NAME"
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        aws iam delete-role --role-name "$ROLE_NAME"
    fi
    handle_error "Failed to list dashboards."
fi
echo "$DASHBOARDS"

# Show instructions for accessing the dashboard
echo ""
echo "Dashboard created successfully! To access it:"
echo "1. Open the CloudWatch console at https://console.aws.amazon.com/cloudwatch/"
echo "2. In the navigation pane, choose Dashboards"
echo "3. Select LambdaMetricsDashboard"
echo "4. You should see a dropdown menu labeled 'Lambda Function' at the top of the dashboard"
echo "5. Use this dropdown to select different Lambda functions and see their metrics"
echo ""

# Create a list of resources for cleanup
RESOURCES=("- CloudWatch Dashboard: LambdaMetricsDashboard")
if [ -n "${FUNCTION_NAME:-}" ]; then
    RESOURCES+=("- Lambda Function: $FUNCTION_NAME")
    RESOURCES+=("- IAM Role: $ROLE_NAME")
fi

# Prompt for cleanup
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Resources created:"
for resource in "${RESOURCES[@]}"; do
    echo "$resource"
done
echo ""
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
    echo "Cleaning up resources..."
    
    # Delete the dashboard
    aws cloudwatch delete-dashboards --dashboard-names LambdaMetricsDashboard
    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to delete dashboard. You may need to delete it manually."
    else
        echo "Dashboard deleted successfully."
    fi
    
    # If we created a Lambda function, delete it and its role
    if [ -n "${FUNCTION_NAME:-}" ]; then
        echo "Deleting Lambda function..."
        aws lambda delete-function --function-name "$FUNCTION_NAME"
        if [ $? -ne 0 ]; then
            echo "WARNING: Failed to delete Lambda function. You may need to delete it manually."
        else
            echo "Lambda function deleted successfully."
        fi
        
        echo "Detaching role policy..."
        aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        if [ $? -ne 0 ]; then
            echo "WARNING: Failed to detach role policy. You may need to detach it manually."
        else
            echo "Role policy detached successfully."
        fi
        
        echo "Deleting IAM role..."
        aws iam delete-role --role-name "$ROLE_NAME"
        if [ $? -ne 0 ]; then
            echo "WARNING: Failed to delete IAM role. You may need to delete it manually."
        else
            echo "IAM role deleted successfully."
        fi
    fi
    
    # Clean up the JSON file
    rm -f dashboard-body.json
    
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

echo "Script completed successfully!"
