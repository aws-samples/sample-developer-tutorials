# Amazon VPC peering

This tutorial demonstrates how to set up VPC peering connections to enable communication between Virtual Private Clouds (VPCs) in the same or different AWS regions, including configuring route tables and security groups.

You can run the shell script to automatically create the VPC peering infrastructure, or follow the step-by-step instructions in the tutorial to manually establish peering connections between your VPCs.

## Resources Created

The script creates the following AWS resources in order:

- EC2 vpc
- EC2 vpc (b)
- EC2 vpc (c)
- EC2 subnet
- EC2 subnet (b)
- EC2 vpc peering connection
- EC2 route table
- EC2 route
- EC2 route table (b)
- EC2 route table (c)
- EC2 route (b)
- EC2 route table (d)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.