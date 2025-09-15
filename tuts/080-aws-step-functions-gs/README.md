# AWS Step Functions getting started

This tutorial guides you through creating and running your first AWS Step Functions state machine using the AWS Command Line Interface (AWS CLI). You'll learn how to create a simple workflow, execute it with different inputs, and integrate with Amazon Comprehend for sentiment analysis.

You can either run the automated shell script (`aws-step-functions-gs.sh`) to quickly set up the entire environment, or follow the step-by-step instructions in the tutorial (`aws-step-functions-gs.md`) to understand each component in detail. Both approaches will help you understand how to build serverless workflows using AWS Step Functions to coordinate multiple AWS services.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM policy
- IAM role policy
- Step Functions state machine
- Step Functions execution
- Step Functions execution (b)
- IAM policy (b)
- IAM role policy (b)
- Step Functions execution (c)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.