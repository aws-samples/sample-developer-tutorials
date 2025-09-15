# Amazon Elastic Kubernetes Service getting started tutorial

This tutorial provides a comprehensive introduction to Amazon Elastic Kubernetes Service (EKS) using the AWS CLI. You'll learn how to create an EKS cluster, configure node groups, and deploy applications to your Kubernetes environment on AWS.

You can either run the provided shell script to automatically set up your EKS cluster and supporting infrastructure, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the cluster configuration for your specific requirements.

## Resources Created

The script creates the following AWS resources in order:

- CloudFormation stack
- IAM role
- IAM role policy
- IAM role (b)
- IAM role policy (b)
- IAM role policy (c)
- IAM role policy (d)
- EKS cluster
- EKS nodegroup

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.