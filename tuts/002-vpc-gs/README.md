# Amazon VPC getting started

This tutorial demonstrates how to get started with Amazon VPC using the AWS CLI. You'll learn the fundamental concepts and operations for working with this AWS service through command-line interface.

You can either run the automated script `vpc-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `vpc-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- EC2 VPC (10.0.0.0/16 CIDR block with DNS support and hostnames enabled)
- EC2 subnet (public subnet in AZ1 - 10.0.0.0/24)
- EC2 subnet (public subnet in AZ2 - 10.0.1.0/24)
- EC2 subnet (private subnet in AZ1 - 10.0.2.0/24)
- EC2 subnet (private subnet in AZ2 - 10.0.3.0/24)
- EC2 internet gateway (for public internet access)
- EC2 route table (public route table with internet gateway route)
- EC2 route table association (public subnet AZ1 to public route table)
- EC2 route table association (public subnet AZ2 to public route table)
- EC2 route table (private route table)
- EC2 route table association (private subnet AZ1 to private route table)
- EC2 route table association (private subnet AZ2 to private route table)
- EC2 elastic IP (for NAT gateway)
- EC2 NAT gateway (in public subnet AZ1 for private subnet internet access)
- EC2 security group (web server security group allowing HTTP/HTTPS)
- EC2 security group (database security group allowing MySQL from web servers)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.