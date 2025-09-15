# Amazon Managed Streaming for Apache Kafka getting started tutorial

This tutorial provides a comprehensive introduction to Amazon Managed Streaming for Apache Kafka (Amazon MSK) using the AWS CLI. You'll learn how to create and configure managed Kafka clusters, set up topics and producers/consumers, and build real-time streaming data pipelines.

You can either run the provided shell script to automatically set up your Amazon MSK cluster and basic streaming infrastructure, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the configuration for your specific streaming data requirements.

## Resources Created

The script creates the following AWS resources in order:

- MSK cluster
- IAM policy
- IAM role
- IAM role policy
- IAM instance profile
- EC2 security group
- EC2 key pair
- EC2 instances

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.