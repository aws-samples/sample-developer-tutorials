# Amazon CloudWatch dynamic dashboard tutorial

This tutorial demonstrates how to create and manage dynamic dashboards in Amazon CloudWatch using the AWS CLI. You'll learn how to set up dashboards that automatically update with metrics from your AWS resources, providing real-time visibility into your infrastructure performance.

You can either run the provided shell script to automatically create the dynamic dashboard resources, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the implementation for your specific monitoring needs.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- Lambda function
- CloudWatch dashboard

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.