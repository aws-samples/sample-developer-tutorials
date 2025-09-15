# Amazon Lightsail getting started

This tutorial demonstrates how to get started with Amazon Lightsail using the AWS CLI. You'll learn the fundamental concepts and operations for working with this AWS service through command-line interface.

You can either run the automated script `lightsail-gs.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `lightsail-gs.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- Lightsail instance (nano_3_0 bundle with Amazon Linux 2023)
- Lightsail disk (8 GB block storage disk)
- Lightsail instance snapshot (backup of the instance)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.