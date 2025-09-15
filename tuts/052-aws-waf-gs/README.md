# AWS WAF getting started tutorial

This tutorial provides a comprehensive introduction to AWS WAF (Web Application Firewall) using the AWS CLI. You'll learn how to create web ACLs, configure rules to protect your applications from common web exploits, and monitor security events to maintain application security.

You can either run the provided shell script to automatically set up your AWS WAF configuration and basic security rules, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the security policies for your specific application protection needs.

## Resources Created

The script creates the following AWS resources in order:

- WAFv2 web acl
- WAFv2 web acl (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.