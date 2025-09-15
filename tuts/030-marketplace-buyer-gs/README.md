# AWS Marketplace buyer getting started

This tutorial demonstrates how to get started as a buyer on AWS Marketplace, covering the essential steps to discover, evaluate, and subscribe to software products. You'll learn how to navigate the marketplace, understand pricing models, manage subscriptions, and integrate purchased software into your AWS environment.

You can either run the automated shell script (`marketplace-buyer-getting-started.sh`) to quickly set up the necessary AWS resources and configurations, or follow the step-by-step instructions in the tutorial (`marketplace-buyer-getting-started.md`) to manually complete each task and gain a deeper understanding of the AWS Marketplace buyer experience.

## Resources Created

The script creates the following AWS resources in order:

- EC2 key pair
- EC2 security group
- EC2 instances

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.