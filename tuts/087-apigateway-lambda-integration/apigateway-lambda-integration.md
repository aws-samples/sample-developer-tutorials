# Create a REST API with Lambda proxy integration using the AWS CLI

This tutorial guides you through creating a REST API with Lambda proxy integration using the AWS Command Line Interface (AWS CLI). You'll learn how to create a Lambda function, set up an API Gateway REST API, configure Lambda proxy integration, and test your API endpoints.

Note: This tutorial is for learning purposes only and is not production-ready. For more info, see [README.md](./README.md).

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials
2. Basic familiarity with command line interfaces and REST API concepts
3. Sufficient permissions to create and manage Lambda functions, API Gateway resources, and IAM roles
4. `jq` command-line JSON processor installed (for parsing AWS CLI responses)
   - **Alternative**: If `jq` is not available, you can manually extract IDs from the AWS CLI output

**Note**: If you don't have `jq` installed, you can install it using:
- **macOS**: `brew install jq`
- **Ubuntu/Debian**: `sudo apt-get install jq`
- **CentOS/RHEL**: `sudo yum install jq`

## Create an IAM role for Lambda execution

Lambda functions require an execution role that grants them permission to access AWS services and write logs to CloudWatch.

**Create a trust policy document**

```bash
cat > trust-policy.json << 'EOF'
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
```

**Create the IAM role**

```bash
aws iam create-role \
    --role-name GetStartedLambdaBasicExecutionRole \
    --assume-role-policy-document file://trust-policy.json
```

**Attach the basic execution policy**

```bash
aws iam attach-role-policy \
    --role-name GetStartedLambdaBasicExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

## Create and deploy a Lambda function

Create a Lambda function that responds to API Gateway requests with a personalized greeting.

**Create the Lambda function code**

```bash
cat > lambda_function.py << 'EOF'
import json

def lambda_handler(event, context):
    print(event)
    
    greeter = 'World'
    
    try:
        if (event['queryStringParameters']) and (event['queryStringParameters']['greeter']) and (
                event['queryStringParameters']['greeter'] is not None):
            greeter = event['queryStringParameters']['greeter']
    except KeyError:
        print('No greeter')
    
    try:
        if (event['multiValueHeaders']) and (event['multiValueHeaders']['greeter']) and (
                event['multiValueHeaders']['greeter'] is not None):
            greeter = " and ".join(event['multiValueHeaders']['greeter'])
    except KeyError:
        print('No greeter')
    
    try:
        if (event['headers']) and (event['headers']['greeter']) and (
                event['headers']['greeter'] is not None):
            greeter = event['headers']['greeter']
    except KeyError:
        print('No greeter')
    
    if (event['body']) and (event['body'] is not None):
        body = json.loads(event['body'])
        try:
            if (body['greeter']) and (body['greeter'] is not None):
                greeter = body['greeter']
        except KeyError:
            print('No greeter')
    
    res = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "*/*"
        },
        "body": "Hello, " + greeter + "!"
    }
    
    return res
EOF
```

**Create a deployment package**

```bash
zip function.zip lambda_function.py
```

**Create the Lambda function**

```bash
aws lambda create-function \
    --function-name GetStartedLambdaProxyIntegration \
    --runtime python3.12 \
    --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/GetStartedLambdaBasicExecutionRole \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://function.zip
```

## Create a REST API

Create a REST API in API Gateway and set up the necessary resources and methods.

**Create the REST API**

```bash
# Create API and capture response
API_RESPONSE=$(aws apigateway create-rest-api \
    --name LambdaProxyAPI \
    --endpoint-configuration types=REGIONAL)

# Extract API ID and root resource ID from response
API_ID=$(echo $API_RESPONSE | jq -r '.id')
ROOT_RESOURCE_ID=$(echo $API_RESPONSE | jq -r '.rootResourceId')

echo "API ID: $API_ID"
echo "Root Resource ID: $ROOT_RESOURCE_ID"
```

**Create a resource**

```bash
# Create resource and capture response
RESOURCE_RESPONSE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part helloworld)

# Extract resource ID from response
RESOURCE_ID=$(echo $RESOURCE_RESPONSE | jq -r '.id')

echo "Resource ID: $RESOURCE_ID"
```

## Configure Lambda proxy integration

Create an ANY method on your resource and configure it to use Lambda proxy integration.

**Create an ANY method**

```bash
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method ANY \
    --authorization-type NONE
```

**Set up Lambda proxy integration**

```bash
# Get account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# If region is not set in config, use default
if [ -z "$REGION" ]; then
    REGION="us-east-1"
fi

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:GetStartedLambdaProxyIntegration/invocations"
```

**Grant API Gateway permission to invoke Lambda**

```bash
aws lambda add-permission \
    --function-name GetStartedLambdaProxyIntegration \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*"
```

## Deploy and test the API

Deploy your API to make it accessible and test it using different methods.

**Deploy the API**

```bash
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name test
```

**Test the API**

Get the invoke URL and test with different methods:

```bash
# Construct the invoke URL
INVOKE_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/test/helloworld"
echo "Invoke URL: $INVOKE_URL"

# Test with query parameter
echo "Testing with query parameter..."
curl -X GET "$INVOKE_URL?greeter=John"

# Test with header
echo "Testing with header..."
curl -X GET "$INVOKE_URL" \
    -H 'content-type: application/json' \
    -H 'greeter: John'

# Test with body
echo "Testing with body..."
curl -X POST "$INVOKE_URL" \
    -H 'content-type: application/json' \
    -d '{ "greeter": "John" }'
```

All tests should return: `Hello, John!`

## Clean up resources

To avoid ongoing charges, delete the resources you created:

```bash
# Delete API
aws apigateway delete-rest-api --rest-api-id $API_ID

# Delete Lambda function
aws lambda delete-function --function-name GetStartedLambdaProxyIntegration

# Delete IAM role
aws iam detach-role-policy \
    --role-name GetStartedLambdaBasicExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam delete-role --role-name GetStartedLambdaBasicExecutionRole

# Clean up local files
rm lambda_function.py function.zip trust-policy.json
```

## Next steps

Now that you've successfully created a REST API with Lambda proxy integration, you can explore additional features:

- Add authentication and authorization to your APIs
- Implement request validation and transformation
- Monitor your APIs with CloudWatch
- Use Lambda layers to share code between functions
