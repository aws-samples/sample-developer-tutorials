# Amazon ECS Fargate Linux

This tutorial shows you how to create and run an Amazon Elastic Container Service (Amazon ECS) Linux task using Fargate with the AWS Command Line Interface (AWS CLI). You'll learn how to create an ECS cluster, register a task definition, create a service, and access your running application.

You can either run the automated shell script (`amazon-ecs-fargate-linux.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`amazon-ecs-fargate-linux.md`) to understand each component in detail. Both approaches will help you understand how to deploy containerized applications on Amazon ECS using Fargate.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- ECS cluster
- ECS task definition
- EC2 security group

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.