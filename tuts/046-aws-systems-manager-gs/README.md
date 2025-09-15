# AWS Systems Manager getting started

This tutorial demonstrates how to get started with AWS Systems Manager using the AWS CLI. You'll learn the fundamental concepts and operations for working with this AWS service through command-line interface.

You can either run the automated script `aws-systems-manager-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `aws-systems-manager-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- IAM policy
- IAM role
- IAM role policy
- Ssm-Quicksetup configuration manager

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.