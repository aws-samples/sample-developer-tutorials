# AWS Direct Connect getting started tutorial

This tutorial provides a comprehensive introduction to AWS Direct Connect using the AWS CLI. You'll learn how to establish dedicated network connections between your on-premises infrastructure and AWS, configure virtual interfaces, and optimize network performance and security for hybrid cloud architectures.

You can either run the provided shell script to automatically set up your Direct Connect configuration and virtual interfaces, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the network setup for your specific connectivity requirements.

## Resources Created

The script creates the following AWS resources in order:

- Directconnect connection
- EC2 vpn gateway
- Directconnect private virtual interface

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.