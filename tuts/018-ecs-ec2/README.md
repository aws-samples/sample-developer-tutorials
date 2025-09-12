# Amazon Elastic Container Service EC2 getting started

This tutorial demonstrates how to get started with Amazon Elastic Container Service (Amazon ECS) using EC2 instances as the compute platform. You'll learn how to create an ECS cluster, define a task definition, and run containerized applications on EC2 instances within your ECS cluster.

You can either run the automated shell script (`ecs-ec2-getting-started.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`ecs-ec2-getting-started.md`) to understand each component and manually configure your ECS environment.

## Resources Created

The script creates the following AWS resources in order:

- ECS cluster
- EC2 key pair
- EC2 security group
- IAM role
- IAM role policy
- IAM instance profile
- EC2 instances
- ECS task definition
- ECS service

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.