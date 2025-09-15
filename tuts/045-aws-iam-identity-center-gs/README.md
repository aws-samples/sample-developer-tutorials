# AWS IAM Identity Center getting started tutorial

This tutorial provides a comprehensive introduction to AWS IAM Identity Center (formerly AWS Single Sign-On) using the AWS CLI. You'll learn how to set up centralized identity management, configure single sign-on access to AWS accounts and applications, and manage user permissions across your organization.

You can either run the provided shell script to automatically configure your IAM Identity Center instance and basic user management, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the identity management setup for your specific organizational requirements.

## Resources Created

The script creates the following AWS resources in order:

- Sso-Admin instance
- Identitystore user
- Identitystore group
- Identitystore group membership
- Sso-Admin permission set
- Sso-Admin managed policy to permission set
- Sso-Admin account assignment
- Sso-Admin application
- Sso-Admin application assignment

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.