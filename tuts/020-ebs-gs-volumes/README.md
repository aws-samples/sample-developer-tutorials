# Amazon EBS getting started volumes

This tutorial guides you through the process of creating and managing Amazon Elastic Block Store (Amazon EBS) volumes using the AWS Command Line Interface (AWS CLI). You'll learn how to create volumes, check their status, attach them to Amazon EC2 instances, and clean up resources when you're done.

You can either run the automated shell script (`ebs-gs-volumes.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`ebs-gs-volumes.md`) to understand each component in detail. Both approaches will help you understand how to work with Amazon EBS volumes for persistent storage with your Amazon EC2 instances.

## Resources Created

The script creates the following AWS resources in order:

- EC2 volume
- EC2 security group
- EC2 instances
- EC2 volume (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.