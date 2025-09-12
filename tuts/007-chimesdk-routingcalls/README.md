# Amazon Chime SDK routing calls

This tutorial demonstrates how to set up call routing with Amazon Chime SDK using the AWS CLI. You'll learn to configure voice connectors, set up routing rules, manage phone numbers, and implement telephony solutions for communication applications.

You can either run the automated script `chimesdk-routingcalls.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `chimesdk-routingcalls.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- Lambda function
- Lambda function (b)
- Chime SDK Voice sip media application
- Chime SDK Voice sip media application (b)
- Chime SDK Voice sip rule

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.