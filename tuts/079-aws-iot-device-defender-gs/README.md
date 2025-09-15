# AWS IoT Device Defender getting started tutorial

This tutorial provides a comprehensive introduction to AWS IoT Device Defender using the AWS CLI. You'll learn how to set up device security monitoring, create security profiles, configure anomaly detection, and implement security best practices for your IoT device fleet.

You can either run the provided shell script to automatically set up your IoT Device Defender configuration and basic security monitoring, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the security setup for your specific IoT device management requirements.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- IAM role policy (b)
- IAM role policy (c)
- IoT Core on demand audit task
- IoT Core mitigation action
- IoT Core audit mitigation actions task
- SNS topic

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.