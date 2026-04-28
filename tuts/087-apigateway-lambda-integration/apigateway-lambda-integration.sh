#!/bin/bash

# Simple API Gateway Lambda Integration Script
# This script creates a REST API with Lambda proxy integration

set -euo pipefail

# Generate random identifiers
FUNCTION_NAME="GetStartedLambdaProxyIntegration-$(openssl rand -hex 4)"
ROLE_NAME="GetStartedLambdaBasicExecutionRole-$(openssl rand -hex 4)"
API_NAME="LambdaProxyAPI-$(openssl rand -hex 4)"

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

# Create temporary directory for cleanup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Creating Lambda function code..."

# Create Lambda function code
cat > "$TEMP_DIR/lambda_function.py" << 'EOF'
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info(json.dumps(event))
    
    greeter = 'World'
    
    # Safely get query string parameters
    query_params = event.get('queryStringParameters') or {}
    if query_params.get('greeter'):
        greeter = query_params['greeter']
    
    # Safely get multi-value headers
    multi_headers = event.get('multiValueHeaders') or {}
    if multi_headers.get('greeter'):
        greeter = " and ".join(multi_headers['greeter'])
    
    # Safely get headers
    headers = event.get('headers') or {}
    if headers.get('greeter'):
        greeter = headers['greeter']
    
    # Safely get body
    body = event.get('body')
    if body:
        try:
            body_dict = json.loads(body)
            if body_dict.get('greeter'):
                greeter = body_dict['greeter']
        except (json.JSONDecodeError, TypeError) as e:
            logger.warning(f"Failed to parse body: {e}")
    
    # Validate greeter to prevent injection
    if not isinstance(greeter, str) or len(greeter) > 256:
        greeter = 'World'
    
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({"message": f"Hello, {greeter}!"})
    }
    
    return response
EOF

# Create deployment package
cd "$TEMP_DIR"
zip function.zip lambda_function.py
cd - > /dev/null

echo "Creating IAM role..."

# Create IAM trust policy
cat > "$TEMP_DIR/trust-policy.json" << 'EOF'
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
aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "file://$TEMP_DIR/trust-policy.json" \
    --region "$REGION"

# Tag IAM role
aws iam tag-role \
    --role-name "$ROLE_NAME" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=apigateway-lambda-integration \
    --region "$REGION"

# Attach execution policy
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    --region "$REGION"

# Wait for role propagation
sleep 15

echo "Creating Lambda function..."

# Create Lambda function
aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.11 \
    --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
    --handler lambda_function.lambda_handler \
    --zip-file "fileb://$TEMP_DIR/function.zip" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=apigateway-lambda-integration \
    --region "$REGION" \
    --timeout 30 \
    --memory-size 256

echo "Creating API Gateway..."

# Create REST API
APIGW_RESPONSE=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --endpoint-configuration types=REGIONAL \
    --region "$REGION" \
    --output json)

# Get API ID from response
API_ID=$(echo "$APIGW_RESPONSE" | jq -r '.id')

if [[ -z "$API_ID" || "$API_ID" == "null" ]]; then
    echo "Error: Failed to create REST API" >&2
    exit 1
fi

# Tag API Gateway
aws apigateway tag-resource \
    --resource-arn "arn:aws:apigateway:$REGION::/restapis/$API_ID" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=apigateway-lambda-integration \
    --region "$REGION"

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --query 'items[?path==`/`].id' --output text --region "$REGION")

if [[ -z "$ROOT_RESOURCE_ID" ]]; then
    echo "Error: Failed to get root resource ID" >&2
    exit 1
fi

# Create helloworld resource
aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_RESOURCE_ID" \
    --path-part helloworld \
    --region "$REGION"

# Get resource ID
RESOURCE_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --query "items[?pathPart=='helloworld'].id" --output text --region "$REGION")

if [[ -z "$RESOURCE_ID" ]]; then
    echo "Error: Failed to get resource ID" >&2
    exit 1
fi

# Create ANY method
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$RESOURCE_ID" \
    --http-method ANY \
    --authorization-type NONE \
    --region "$REGION"

# Set up Lambda proxy integration
LAMBDA_URI="arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME/invocations"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$RESOURCE_ID" \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$LAMBDA_URI" \
    --region "$REGION"

# Grant API Gateway permission to invoke Lambda
SOURCE_ARN="arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"

STATEMENT_ID="apigateway-invoke-$(openssl rand -hex 4)"

aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "$STATEMENT_ID" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "$SOURCE_ARN" \
    --region "$REGION"

# Deploy API
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name test \
    --region "$REGION"

echo "Testing API..."

# Test the API
INVOKE_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/test/helloworld"

echo "API URL: $INVOKE_URL"

# Test with query parameter
echo "Testing with query parameter:"
curl -s -X GET "$INVOKE_URL?greeter=John" | jq . || true
echo ""

# Test with header
echo "Testing with header:"
curl -s -X GET "$INVOKE_URL" \
    -H 'Content-Type: application/json' \
    -H 'greeter: John' | jq . || true
echo ""

# Test with body
echo "Testing with POST body:"
curl -s -X POST "$INVOKE_URL" \
    -H 'Content-Type: application/json' \
    -d '{"greeter": "John"}' | jq . || true
echo ""

echo "Tutorial completed! API is available at: $INVOKE_URL"

# Cleanup
echo "Cleaning up resources..."

# Delete API
aws apigateway delete-rest-api --rest-api-id "$API_ID" --region "$REGION"

# Delete Lambda function
aws lambda delete-function --function-name "$FUNCTION_NAME" --region "$REGION"

# Detach policy and delete role
aws iam detach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    --region "$REGION"

aws iam delete-role --role-name "$ROLE_NAME" --region "$REGION"

echo "Cleanup completed!"