# AWS Batch with Fargate getting started

This tutorial demonstrates how to run batch jobs with AWS Batch and Fargate using the AWS CLI. You'll learn to create job definitions, configure compute environments, submit jobs, and monitor batch processing workloads in a serverless environment.

You can either run the automated script `getting-started-batch-fargate.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `getting-started-batch-fargate.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- Batch compute environment
- Batch job queue
- Batch job definition

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.