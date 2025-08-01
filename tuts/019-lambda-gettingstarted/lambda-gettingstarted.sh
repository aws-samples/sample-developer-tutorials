#!/bin/bash

# Lambda Getting Started Tutorial Script - Version 3
# This script creates a Lambda function, tests it, and cleans up resources

# Set up logging
LOG_FILE="lambda_tutorial_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Lambda Getting Started Tutorial Script"
echo "Logging to $LOG_FILE"
echo "=============================================="

# Function to handle errors
handle_error() {
  echo "ERROR: $1"
  echo "Resources created:"
  if [ -n "$ROLE_NAME" ]; then echo "- IAM Role: $ROLE_NAME"; fi
  if [ -n "$FUNCTION_NAME" ]; then echo "- Lambda Function: $FUNCTION_NAME"; fi
  if [ -n "$LOG_GROUP_NAME" ]; then echo "- CloudWatch Log Group: $LOG_GROUP_NAME"; fi
  
  echo "Attempting to clean up resources..."
  cleanup
  exit 1
}

# Function to clean up resources
cleanup() {
  echo "Cleaning up resources..."
  
  # Delete Lambda function if it exists
  if [ -n "$FUNCTION_NAME" ]; then
    echo "Deleting Lambda function: $FUNCTION_NAME"
    aws lambda delete-function --function-name "$FUNCTION_NAME" || echo "Failed to delete Lambda function"
  fi
  
  # Wait for Lambda function to be deleted before deleting the role
  if [ -n "$FUNCTION_NAME" ]; then
    echo "Waiting for Lambda function to be deleted..."
    aws lambda get-function --function-name "$FUNCTION_NAME" 2>/dev/null
    while [ $? -eq 0 ]; do
      sleep 2
      aws lambda get-function --function-name "$FUNCTION_NAME" 2>/dev/null
    done
  fi
  
  # Delete CloudWatch log group if it exists
  if [ -n "$LOG_GROUP_NAME" ]; then
    echo "Deleting CloudWatch log group: $LOG_GROUP_NAME"
    aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME" 2>/dev/null || echo "Log group not found or already deleted"
  fi
  
  # Delete IAM role if it exists
  if [ -n "$ROLE_NAME" ]; then
    echo "Detaching policy from role: $ROLE_NAME"
    aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" || echo "Failed to detach policy"
    
    echo "Deleting IAM role: $ROLE_NAME"
    aws iam delete-role --role-name "$ROLE_NAME" || echo "Failed to delete IAM role"
  fi
  
  # Remove temporary files
  rm -f function.zip test-event.json output.json trust-policy.json 2>/dev/null
  
  echo "Cleanup completed"
}

# Function to prompt for runtime choice
choose_runtime() {
  echo ""
  echo "=============================================="
  echo "CHOOSE RUNTIME"
  echo "=============================================="
  echo "Select a runtime for your Lambda function:"
  echo "1) Node.js 22.x"
  echo "2) Python 3.13"
  echo "Enter your choice (1 or 2): "
  read -r RUNTIME_CHOICE
  
  if [ "$RUNTIME_CHOICE" = "1" ]; then
    RUNTIME="nodejs22.x"
    HANDLER="index.handler"
    CODE_FILE="index.mjs"
    echo "You selected Node.js 22.x"
  elif [ "$RUNTIME_CHOICE" = "2" ]; then
    RUNTIME="python3.13"
    HANDLER="lambda_function.lambda_handler"
    CODE_FILE="lambda_function.py"
    echo "You selected Python 3.13"
  else
    echo "Invalid choice. Defaulting to Node.js 22.x"
    RUNTIME="nodejs22.x"
    HANDLER="index.handler"
    CODE_FILE="index.mjs"
  fi
}

# Function to wait for Lambda function to be active
wait_for_function_active() {
  local function_name=$1
  local max_attempts=30
  local attempt=1
  local state=""
  
  echo "Waiting for Lambda function to become active..."
  
  while [ $attempt -le $max_attempts ]; do
    state=$(aws lambda get-function --function-name "$function_name" --query 'Configuration.State' --output text 2>/dev/null)
    
    if [ "$state" = "Active" ]; then
      echo "Lambda function is now active"
      return 0
    fi
    
    echo "Function state: $state (attempt $attempt/$max_attempts)"
    sleep 2
    ((attempt++))
  done
  
  echo "Timed out waiting for function to become active"
  return 1
}

# Set variables
FUNCTION_NAME="myLambdaFunction"
ROLE_NAME="lambda-tutorial-role-$(date +%s)"
LOG_GROUP_NAME="/aws/lambda/$FUNCTION_NAME"

# Choose runtime
choose_runtime

echo "Creating resources for Lambda tutorial..."

# Step 1: Create IAM role for Lambda
echo "Creating IAM role: $ROLE_NAME"

# Create trust policy document
cat > trust-policy.json << EOF
{
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
}
EOF

# Create IAM role
ROLE_ARN=$(aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json \
  --query 'Role.Arn' \
  --output text)

if [ -z "$ROLE_ARN" ]; then
  handle_error "Failed to create IAM role"
fi

echo "Created IAM role: $ROLE_ARN"

# Attach Lambda basic execution policy to the role
echo "Attaching Lambda basic execution policy to role"
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" || handle_error "Failed to attach policy to role"

# Wait for role to propagate
echo "Waiting for IAM role to propagate..."
sleep 10

# Step 2: Create function code
echo "Creating function code for $RUNTIME"

if [ "$RUNTIME" = "nodejs22.x" ]; then
  # Create Node.js function code
  cat > index.mjs << EOF
export const handler = async (event, context) => {
  
  const length = event.length;
  const width = event.width;
  let area = calculateArea(length, width);
  console.log(\`The area is \${area}\`);
        
  console.log('CloudWatch log group: ', context.logGroupName);
  
  let data = {
    "area": area,
  };
    return JSON.stringify(data);
    
  function calculateArea(length, width) {
    return length * width;
  }
};
EOF
else
  # Create Python function code
  cat > lambda_function.py << EOF
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    # Get the length and width parameters from the event object
    length = event['length']
    width = event['width']
    
    area = calculate_area(length, width)
    print(f"The area is {area}")
        
    logger.info(f"CloudWatch logs group: {context.log_group_name}")
    
    # return the calculated area as a JSON string
    data = {"area": area}
    return json.dumps(data)
    
def calculate_area(length, width):
    return length*width
EOF
fi

# Create ZIP deployment package
echo "Creating deployment package"
zip function.zip "$CODE_FILE" || handle_error "Failed to create ZIP file"

# Step 3: Create Lambda function
echo "Creating Lambda function: $FUNCTION_NAME"
FUNCTION_ARN=$(aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime "$RUNTIME" \
  --handler "$HANDLER" \
  --role "$ROLE_ARN" \
  --zip-file fileb://function.zip \
  --architectures x86_64 \
  --query 'FunctionArn' \
  --output text)

if [ -z "$FUNCTION_ARN" ]; then
  handle_error "Failed to create Lambda function"
fi

echo "Created Lambda function: $FUNCTION_ARN"

# Wait for the function to become active
wait_for_function_active "$FUNCTION_NAME" || handle_error "Function did not become active in time"

# Step 4: Create test event
echo "Creating test event"
cat > test-event.json << EOF
{
  "length": 6,
  "width": 7
}
EOF

# Step 5: Invoke the function
echo "Invoking Lambda function with test event"
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload fileb://test-event.json \
  output.json || handle_error "Failed to invoke Lambda function"

echo "Function response:"
cat output.json
echo ""

# Step 6: Wait for logs to be available
echo "Waiting for logs to be available..."
sleep 10

echo "Getting CloudWatch logs for function"
LOG_STREAMS=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text 2>/dev/null)

if [ -n "$LOG_STREAMS" ] && [ "$LOG_STREAMS" != "None" ]; then
  echo "Log stream found: $LOG_STREAMS"
  echo "Log events:"
  aws logs get-log-events \
    --log-group-name "$LOG_GROUP_NAME" \
    --log-stream-name "$LOG_STREAMS" \
    --query 'events[*].message' \
    --output text
else
  echo "No log streams found yet. Logs may take a moment to appear."
  echo "You can check logs later in the CloudWatch console at:"
  echo "https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/$LOG_GROUP_NAME"
fi

# Display summary of created resources
echo ""
echo "=============================================="
echo "RESOURCES CREATED"
echo "=============================================="
echo "- IAM Role: $ROLE_NAME"
echo "- Lambda Function: $FUNCTION_NAME"
echo "- CloudWatch Log Group: $LOG_GROUP_NAME"

# Prompt for cleanup
echo ""
echo "=============================================="
echo "CLEANUP CONFIRMATION"
echo "=============================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
  cleanup
else
  echo "Resources were not cleaned up. You can manually delete them later."
  echo "To clean up resources manually:"
  echo "1. Delete Lambda function: aws lambda delete-function --function-name $FUNCTION_NAME"
  echo "2. Delete CloudWatch log group: aws logs delete-log-group --log-group-name $LOG_GROUP_NAME"
  echo "3. Detach policy: aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  echo "4. Delete IAM role: aws iam delete-role --role-name $ROLE_NAME"
fi

echo "Script completed successfully"
