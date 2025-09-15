# Amazon Elastic Container Registry getting started

This tutorial guides you through the process of creating, pushing, pulling, and managing Docker container images with Amazon Elastic Container Registry (Amazon ECR) using the AWS Command Line Interface (AWS CLI). You'll learn how to create repositories, authenticate with Docker, and manage container images in a secure registry.

You can either run the automated shell script (`amazon-elastic-container-registry-gs.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`amazon-elastic-container-registry-gs.md`) to understand each component in detail. Both approaches will help you understand how to use Amazon ECR as a fully managed container registry for storing and managing your Docker images.

## Resources Created

The script creates the following AWS resources in order:

- Ecr repository

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.