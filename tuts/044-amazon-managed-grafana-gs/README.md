# Amazon Managed Grafana getting started tutorial

This tutorial provides a comprehensive introduction to Amazon Managed Grafana using the AWS CLI. You'll learn how to create and configure a managed Grafana workspace, set up data sources, create dashboards, and visualize metrics from your AWS services and applications.

You can either run the provided shell script to automatically set up your Amazon Managed Grafana workspace and basic configurations, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the setup for your specific monitoring and visualization needs.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM policy
- IAM role policy
- Grafana workspace

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.