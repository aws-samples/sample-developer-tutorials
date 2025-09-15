# Amazon EC2 basics

This tutorial demonstrates the basic operations for working with Amazon Elastic Compute Cloud (EC2) instances, including creating, configuring, and managing virtual servers in the AWS cloud.

You can either run the automated script `ec2-basics.sh` to execute all the steps automatically, or follow the step-by-step instructions in the `ec2-basics.md` tutorial to understand each operation in detail.

## Resources Created

The script creates the following AWS resources in order:

- EC2 key pair
- EC2 security group
- EC2 instances
- EC2 instances (b)
- EC2 address
- EC2 address (b)
- EC2 instances (c)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.