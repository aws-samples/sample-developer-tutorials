# Amazon WorkSpaces personal tutorial

This tutorial demonstrates how to set up and manage personal Amazon WorkSpaces using the AWS CLI. You'll learn how to create virtual desktop environments in the cloud, configure user access, and manage WorkSpaces for individual users or small teams.

You can either run the provided shell script to automatically provision your WorkSpaces environment and user configurations, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the setup for your specific organizational needs.

## Resources Created

The script creates the following AWS resources in order:

- WorkSpaces workspace directory
- WorkSpaces workspaces

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.