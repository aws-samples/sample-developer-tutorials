# AWS Secrets Manager getting started

This tutorial introduces AWS Secrets Manager, showing how to securely store, retrieve, and manage sensitive information such as database credentials, API keys, and other secrets used by your applications.

You can either run the automated script `aws-secrets-manager-gs.sh` to execute all the steps automatically, or follow the step-by-step instructions in the `aws-secrets-manager-gs.md` tutorial to understand each operation in detail.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- IAM role (b)
- Secrets Manager secret
- Secrets Manager resource policy

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.