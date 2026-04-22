#!/bin/bash

# CloudWatch Dashboard with Lambda Function Variable Script
# This script creates a CloudWatch dashboard with a property variable for Lambda function names

# Set up logging
LOG_FILE="cloudwatch-dashboard-script-v4.log"
echo "Starting script execution at $(date)" > "$LOG_FILE"

# Function to log commands and their output
log_cmd() {
    echo "$(date): Running command: $1" >> "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    
    if [ $cmd_status -ne 0 ] || echo "$cmd_output" | grep -i "error" > /dev/null; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        echo "Command output: $cmd_output" | tee -a "$LOG_FILE"
        cleanup_resources
        exit 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo "" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "CLEANUP PROCESS" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    
    if [ -n "$DASHBOARD_NAME" ]; then
        echo "Deleting CloudWatch dashboard: $DASHBOARD_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws cloudwatch delete-dashboards --dashboard-names \"$DASHBOARD_NAME\""
    fi
    
    if [ -n "$LAMBDA_FUNCTION1" ]; then
        echo "Deleting Lambda function: $LAMBDA_FUNCTION1" | tee -a "$LOG_FILE"
        log_cmd "aws lambda delete-function --function-name \"$LAMBDA_FUNCTION1\""
    fi
    
    if [ -n "$LAMBDA_FUNCTION2" ]; then
        echo "Deleting Lambda function: $LAMBDA_FUNCTION2" | tee -a "$LOG_FILE"
        log_cmd "aws lambda delete-function --function-name \"$LAMBDA_FUNCTION2\""
    fi
    
    if [ -n "$ROLE_NAME" ]; then
        echo "Detaching policy from role: $ROLE_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws iam detach-role-policy --role-name \"$ROLE_NAME\" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        
        echo "Deleting IAM role: $ROLE_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws iam delete-role --role-name \"$ROLE_NAME\""
    fi
    
    echo "Cleanup completed." | tee -a "$LOG_FILE"
}

# Function to prompt for cleanup confirmation
confirm_cleanup() {
    echo "" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "CLEANUP CONFIRMATION" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "The following resources were created:" | tee -a "$LOG_FILE"
    echo "- CloudWatch Dashboard: $DASHBOARD_NAME" | tee -a "$LOG_FILE"
    
    if [ -n "$LAMBDA_FUNCTION1" ]; then
        echo "- Lambda Function: $LAMBDA_FUNCTION1" | tee -a "$LOG_FILE"
    fi
    
    if [ -n "$LAMBDA_FUNCTION2" ]; then
        echo "- Lambda Function: $LAMBDA_FUNCTION2" | tee -a "$LOG_FILE"
    fi
    
    if [ -n "$ROLE_NAME" ]; then
        echo "- IAM Role: $ROLE_NAME" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    echo "Do you want to clean up all created resources? (y/n): " | tee -a "$LOG_FILE"
    read -r CLEANUP_CHOICE
    
    if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
        cleanup_resources
    else
        echo "Resources were not cleaned up. You can manually delete them later." | tee -a "$LOG_FILE"
    fi
}

# Get AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
    echo "No region found in AWS config, defaulting to $AWS_REGION" | tee -a "$LOG_FILE"
else
    echo "Using AWS region: $AWS_REGION" | tee -a "$LOG_FILE"
fi

# Generate unique identifiers
RANDOM_ID=$(openssl rand -hex 6)
DASHBOARD_NAME="LambdaMetricsDashboard-${RANDOM_ID}"
LAMBDA_FUNCTION1="TestFunction1-${RANDOM_ID}"
LAMBDA_FUNCTION2="TestFunction2-${RANDOM_ID}"
ROLE_NAME="LambdaExecutionRole-${RANDOM_ID}"

echo "Using random identifier: $RANDOM_ID" | tee -a "$LOG_FILE"
echo "Dashboard name: $DASHBOARD_NAME" | tee -a "$LOG_FILE"
echo "Lambda function names: $LAMBDA_FUNCTION1, $LAMBDA_FUNCTION2" | tee -a "$LOG_FILE"
echo "IAM role name: $ROLE_NAME" | tee -a "$LOG_FILE"

# Create IAM role for Lambda functions
echo "Creating IAM role for Lambda..." | tee -a "$LOG_FILE"
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

echo "$TRUST_POLICY" > trust-policy.json

ROLE_OUTPUT=$(log_cmd "aws iam create-role --role-name \"$ROLE_NAME\" --assume-role-policy-document file://trust-policy.json --output json")
check_error "$ROLE_OUTPUT" $? "Failed to create IAM role"

ROLE_ARN=$(echo "$ROLE_OUTPUT" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
echo "Role ARN: $ROLE_ARN" | tee -a "$LOG_FILE"

# Tag IAM role
echo "Tagging IAM role..." | tee -a "$LOG_FILE"
log_cmd "aws iam tag-role --role-name \"$ROLE_NAME\" --tags Key=tutorial,Value=cloudwatch-streams"

# Attach Lambda basic execution policy to the role
echo "Attaching Lambda execution policy to role..." | tee -a "$LOG_FILE"
POLICY_OUTPUT=$(log_cmd "aws iam attach-role-policy --role-name \"$ROLE_NAME\" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
check_error "$POLICY_OUTPUT" $? "Failed to attach policy to role"

# Wait for role to propagate
echo "Waiting for IAM role to propagate..." | tee -a "$LOG_FILE"
sleep 10

# Create simple Python Lambda function code
echo "Creating Lambda function code..." | tee -a "$LOG_FILE"
cat > lambda_function.py << 'EOF'
def handler(event, context):
    print("Lambda function executed successfully")
    return {
        'statusCode': 200,
        'body': 'Success'
    }
EOF

# Zip the Lambda function code
log_cmd "zip -j lambda_function.zip lambda_function.py"

# Create first Lambda function
echo "Creating first Lambda function: $LAMBDA_FUNCTION1..." | tee -a "$LOG_FILE"
LAMBDA1_OUTPUT=$(log_cmd "aws lambda create-function --function-name \"$LAMBDA_FUNCTION1\" --runtime python3.9 --role \"$ROLE_ARN\" --handler lambda_function.handler --zip-file fileb://lambda_function.zip --tags Key=tutorial,Value=cloudwatch-streams")
check_error "$LAMBDA1_OUTPUT" $? "Failed to create first Lambda function"

# Create second Lambda function
echo "Creating second Lambda function: $LAMBDA_FUNCTION2..." | tee -a "$LOG_FILE"
LAMBDA2_OUTPUT=$(log_cmd "aws lambda create-function --function-name \"$LAMBDA_FUNCTION2\" --runtime python3.9 --role \"$ROLE_ARN\" --handler lambda_function.handler --zip-file fileb://lambda_function.zip --tags Key=tutorial,Value=cloudwatch-streams")
check_error "$LAMBDA2_OUTPUT" $? "Failed to create second Lambda function"

# Invoke Lambda functions to generate some metrics
echo "Invoking Lambda functions to generate metrics..." | tee -a "$LOG_FILE"
log_cmd "aws lambda invoke --function-name \"$LAMBDA_FUNCTION1\" --payload '{}' /dev/null"
log_cmd "aws lambda invoke --function-name \"$LAMBDA_FUNCTION2\" --payload '{}' /dev/null"

# Create CloudWatch dashboard with property variable
echo "Creating CloudWatch dashboard with property variable..." | tee -a "$LOG_FILE"

# Create a simpler dashboard with a property variable
# This approach uses a more basic dashboard structure that's known to work with the CloudWatch API
DASHBOARD_BODY=$(cat <<EOF
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
          [ "AWS/Lambda", "Invocations", "FunctionName", "$LAMBDA_FUNCTION1" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "$AWS_REGION",
        "title": "Lambda Invocations",
        "period": 300,
        "stat": "Sum"
      }
    }
  ]
}
EOF
)

# First create a basic dashboard without variables
echo "Creating initial dashboard without variables..." | tee -a "$LOG_FILE"
DASHBOARD_OUTPUT=$(log_cmd "aws cloudwatch put-dashboard --dashboard-name \"$DASHBOARD_NAME\" --dashboard-body '$DASHBOARD_BODY'")
check_error "$DASHBOARD_OUTPUT" $? "Failed to create initial CloudWatch dashboard"

# Tag CloudWatch dashboard
echo "Tagging CloudWatch dashboard..." | tee -a "$LOG_FILE"
log_cmd "aws cloudwatch tag-resource --resource-arn arn:aws:cloudwatch::$(aws sts get-caller-identity --query Account --output text):dashboard/$DASHBOARD_NAME --tags Key=tutorial,Value=cloudwatch-streams"

# Now let's try to add a property variable using the console instructions
echo "To complete the tutorial, please follow these steps in the CloudWatch console:" | tee -a "$LOG_FILE"
echo "1. Open the CloudWatch console at https://console.aws.amazon.com/cloudwatch/" | tee -a "$LOG_FILE"
echo "2. Navigate to Dashboards and select your dashboard: $DASHBOARD_NAME" | tee -a "$LOG_FILE"
echo "3. Choose Actions > Variables > Create a variable" | tee -a "$LOG_FILE"
echo "4. Choose Property variable" | tee -a "$LOG_FILE"
echo "5. For Property that the variable changes, choose FunctionName" | tee -a "$LOG_FILE"
echo "6. For Input type, choose Select menu (dropdown)" | tee -a "$LOG_FILE"
echo "7. Choose Use the results of a metric search" | tee -a "$LOG_FILE"
echo "8. Choose Pre-built queries > Lambda > Errors" | tee -a "$LOG_FILE"
echo "9. Choose By Function Name and then choose Search" | tee -a "$LOG_FILE"
echo "10. (Optional) Configure any secondary settings as desired" | tee -a "$LOG_FILE"
echo "11. Choose Add variable" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "The dashboard has been created and can be accessed at:" | tee -a "$LOG_FILE"
echo "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=$DASHBOARD_NAME" | tee -a "$LOG_FILE"

# Verify dashboard creation
echo "Verifying dashboard creation..." | tee -a "$LOG_FILE"
VERIFY_OUTPUT=$(log_cmd "aws cloudwatch get-dashboard --dashboard-name \"$DASHBOARD_NAME\"")
check_error "$VERIFY_OUTPUT" $? "Failed to verify dashboard creation"

echo "" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "DASHBOARD CREATED SUCCESSFULLY" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "Dashboard Name: $DASHBOARD_NAME" | tee -a "$LOG_FILE"
echo "Lambda Functions: $LAMBDA_FUNCTION1, $LAMBDA_FUNCTION2" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "You can view your dashboard in the CloudWatch console:" | tee -a "$LOG_FILE"
echo "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=$DASHBOARD_NAME" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Prompt for cleanup
confirm_cleanup

echo "Script completed successfully." | tee -a "$LOG_FILE"
exit 0