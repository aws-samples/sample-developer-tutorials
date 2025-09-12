# Amazon VPC private servers getting started

This tutorial demonstrates how to configure private servers in Amazon VPC using the AWS CLI. You'll learn to set up isolated network environments, configure private subnets, implement bastion hosts, and secure server access patterns.

You can either run the automated script `vpc-private-servers-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `vpc-private-servers-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- EC2 vpc
- EC2 subnet
- EC2 subnet (b)
- EC2 subnet (c)
- EC2 subnet (d)
- EC2 internet gateway
- EC2 internet gateway (b)
- EC2 route table
- EC2 route table (b)
- EC2 route table (c)
- EC2 route
- EC2 route table (d)
- EC2 route table (e)
- EC2 route table (f)
- EC2 route table (g)
- EC2 address
- EC2 address (b)
- EC2 nat gateway
- EC2 nat gateway (b)
- EC2 route (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.