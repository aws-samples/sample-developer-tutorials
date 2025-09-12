# AWS Config getting started tutorial

This tutorial provides a comprehensive introduction to AWS Config using the AWS CLI. You'll learn how to set up configuration recording, create compliance rules, track resource changes, and maintain governance across your AWS infrastructure through automated configuration management.

You can either run the provided shell script to automatically configure AWS Config and basic compliance rules, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the configuration management setup for your specific compliance and governance requirements.

## Resources Created

The script creates the following AWS resources in order:

- S3 bucket
- S3 bucket (b)
- S3 public access block
- SNS topic
- IAM role
- IAM role policy
- IAM role policy (b)
- Configservice configuration recorder
- Configservice delivery channel
- Configservice delivery channel (b)
- Configservice configuration recorder (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.