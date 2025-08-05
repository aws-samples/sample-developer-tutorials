# AWS Network Firewall getting started

This tutorial demonstrates how to get started with AWS Network Firewall using the AWS CLI. You'll learn the fundamental concepts and operations for working with this AWS service through command-line interface.

You can either run the automated script `aws-network-firewall-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `aws-network-firewall-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

• EC2 route
• Network-Firewall rule group
• Network-Firewall rule group (b)
• Network-Firewall firewall policy
• Network-Firewall firewall
• EC2 route table
• EC2 route (b)
• EC2 route (c)
• EC2 route (d)
• EC2 route (e)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.