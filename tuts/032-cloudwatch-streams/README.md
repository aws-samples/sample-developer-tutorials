# Amazon CloudWatch streams

This tutorial demonstrates how to work with Amazon CloudWatch log streams by creating log groups, configuring log streams, and managing log data for monitoring and troubleshooting applications.

You can run the shell script to automatically set up the CloudWatch log resources, or follow the step-by-step instructions in the tutorial to manually configure your logging infrastructure.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- Lambda function
- Lambda function (b)
- CloudWatch dashboard

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.