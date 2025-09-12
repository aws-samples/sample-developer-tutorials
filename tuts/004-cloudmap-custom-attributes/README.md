# AWS Cloud Map custom attributes

This tutorial demonstrates how to configure AWS Cloud Map with custom attributes using the AWS CLI. You'll learn to create service discovery namespaces, register services with custom metadata, and query services based on custom attributes for advanced service discovery scenarios.

You can either run the automated script `cloudmap-custom-attributes.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `cloudmap-custom-attributes.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- Service Discovery http namespace
- Service Discovery http namespace (b)
- DynamoDB table
- Service Discovery service
- Service Discovery instance
- Service Discovery instance (b)
- IAM role
- IAM policy
- IAM role policy
- IAM role policy (b)
- Service Discovery service (b)
- Lambda function
- Service Discovery instance (c)
- Service Discovery instance (d)
- Lambda function (b)
- Service Discovery instance (e)
- Service Discovery instance (f)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.