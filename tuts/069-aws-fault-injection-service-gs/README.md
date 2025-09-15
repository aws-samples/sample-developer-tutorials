# AWS Fault Injection Service getting started

This tutorial guides you through using AWS Fault Injection Service to run CPU stress tests on an Amazon EC2 instance. You'll learn how to create the necessary IAM roles, set up a CloudWatch alarm as a stop condition, create and run an experiment, and monitor the results to understand how your applications respond to fault conditions.

You can either run the automated shell script (`aws-fault-injection-service-getting-started.sh`) to quickly set up and execute the entire tutorial, or follow the step-by-step instructions in the tutorial document (`aws-fault-injection-service-getting-started.md`) to manually perform each step and gain a deeper understanding of the AWS Fault Injection Service workflow.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role (b)
- IAM role policy
- IAM role policy (b)
- IAM role (c)
- IAM role (d)
- IAM role policy (c)
- IAM role policy (d)
- IAM instance profile
- IAM instance profile (b)
- EC2 instances
- EC2 instances (b)
- CloudWatch metric alarm
- CloudWatch metric alarm (b)
- Fis experiment template
- Fis experiment template (b)
- Fis experiment
- Fis experiment (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.