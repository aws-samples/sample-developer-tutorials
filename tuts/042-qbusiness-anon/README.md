# Amazon Q Business anonymous access

This tutorial demonstrates how to configure anonymous access for Amazon Q Business using the AWS CLI. You'll learn to set up anonymous user access, configure permissions, and implement secure anonymous interactions with Q Business applications.

You can either run the automated script `qbusiness-anon.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `qbusiness-anon.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- Qbusiness application

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.