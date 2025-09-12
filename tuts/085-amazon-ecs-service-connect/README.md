# Amazon ECS Service Connect

This tutorial guides you through setting up Amazon Elastic Container Service (Amazon ECS) Service Connect using the AWS Command Line Interface (AWS CLI). You'll learn how to create an ECS cluster with Service Connect enabled, deploy a containerized application, and configure service discovery for inter-service communication.

You can either run the automated shell script (`amazon-ecs-service-connect.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`amazon-ecs-service-connect.md`) to understand each component in detail. Both approaches will help you understand how to implement service-to-service communication in Amazon ECS using Service Connect.

## Resources Created

The script creates the following AWS resources in order:

- EC2 security group
- Logs log group
- Logs log group (b)
- ECS cluster
- IAM role
- ECS task definition
- ECS service

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.