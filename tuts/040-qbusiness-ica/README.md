# Amazon Q Business ICA

This tutorial guides you through creating an Amazon Q Business application with Identity Center Authentication (ICA) using the AWS CLI. Amazon Q Business is a generative AI-powered assistant that helps your employees find information and complete tasks within your organization. The tutorial covers setting up AWS IAM Identity Center, creating necessary IAM roles and policies, configuring user access, and optionally creating a web experience for browser-based access.

You can either run the automated shell script `qbusiness-ica.sh` to create all the resources at once, or follow the step-by-step instructions in the `qbusiness-ica.md` tutorial to understand each component in detail. The tutorial includes cleanup steps to avoid ongoing charges and best practices for production deployments.

## Resources Created

The script creates the following AWS resources in order:

- IAM role for Amazon Q Business application (with CloudWatch and logging permissions)
- IAM policy with necessary permissions for the application role
- Amazon Q Business application
- User assignment to the application
- User subscription for the application

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.
