# Amazon CloudFront getting started

This tutorial demonstrates how to set up and configure Amazon CloudFront distributions using the AWS CLI. You'll learn to create distributions, configure origins, set up caching behaviors, and implement content delivery optimization for global web applications.

You can either run the automated script `cloudfront-gettingstarted.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `cloudfront-gettingstarted.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- CloudFront origin access control
- CloudFront distribution
- S3 bucket policy

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.