# Amazon VPC IPAM getting started

This tutorial demonstrates how to set up IP Address Manager (IPAM) for Amazon VPC using the AWS CLI. You'll learn to create IPAM pools, manage IP address allocation, monitor IP usage, and implement centralized IP address management across multiple VPCs.

You can either run the automated script `vpc-ipam-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `vpc-ipam-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- EC2 ipam
- EC2 ipam pool
- EC2 ipam pool (b)
- EC2 ipam pool (c)
- EC2 vpc

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.