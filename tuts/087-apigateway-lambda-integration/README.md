# API Gateway Lambda Integration Tutorial

This tutorial demonstrates how to create a REST API with Lambda proxy integration using the AWS CLI.

## Files

- `apigateway-lambda-integration.md` - Step-by-step tutorial
- `apigateway-lambda-integration.sh` - Automated execution script

## Usage

### Manual execution following the tutorial
```bash
# Read the tutorial and execute commands manually
cat apigateway-lambda-integration.md
```

### Automated execution with script
```bash
# Execute all steps automatically
chmod +x apigateway-lambda-integration.sh
./apigateway-lambda-integration.sh
```

## Prerequisites

- AWS CLI configured
- Appropriate IAM permissions

## Security Warning

This tutorial is for learning purposes only and is not production-ready.

### High Risk Issues

- **Public API**: Creates an unauthenticated API accessible to anyone on the internet
- **Overly permissive permissions**: Lambda can be invoked by any API Gateway method/resource

### Medium Risk Issues

- **No input validation**: User inputs are processed without sanitization
- **Information disclosure**: Lambda logs full request data to CloudWatch
- **No rate limiting**: API has no protection against abuse

Before production use, you must:
- Add authentication (AWS_IAM, API keys, or Cognito)
- Implement input validation and sanitization
- Remove debug logging of sensitive data
- Configure rate limiting and throttling

## Resources Created

- Lambda function
- API Gateway REST API
- IAM role

All resources are automatically cleaned up after script execution.
