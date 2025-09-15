# AWS Transit Gateway getting started

This tutorial demonstrates how to set up and configure AWS Transit Gateway using the AWS CLI. You'll learn to create transit gateways, attach VPCs, configure route tables, and implement scalable network connectivity between multiple VPCs and on-premises networks.

You can either run the automated script `transitgateway-gettingstarted.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `transitgateway-gettingstarted.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- EC2 vpc
- EC2 subnet
- EC2 subnet (b)
- EC2 vpc (b)
- EC2 subnet (c)
- EC2 subnet (d)
- EC2 transit gateway
- EC2 transit gateway vpc attachment
- EC2 transit gateway vpc attachment (b)
- EC2 route
- EC2 route (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.