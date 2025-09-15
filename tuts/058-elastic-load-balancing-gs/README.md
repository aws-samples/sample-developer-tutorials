# Elastic Load Balancing getting started

This tutorial guides you through creating and configuring an Application Load Balancer using the AWS Command Line Interface (AWS CLI). You'll learn how to create a load balancer, configure target groups, register targets, and set up listeners to distribute traffic to your applications.

You can either run the automated shell script (`elastic-load-balancing-gs.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`elastic-load-balancing-gs.md`) to understand each component in detail. Both approaches will help you understand how to use Elastic Load Balancing to distribute incoming traffic across multiple targets for improved availability and fault tolerance.

## Resources Created

The script creates the following AWS resources in order:

- EC2 security group
- ELBv2 load balancer
- ELBv2 target group
- ELBv2 targets
- ELBv2 listener

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.