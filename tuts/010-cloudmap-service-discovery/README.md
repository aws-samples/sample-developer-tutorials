# AWS Cloud Map service discovery

This tutorial demonstrates how to implement service discovery with AWS Cloud Map using the AWS CLI. You'll learn to create namespaces, register services, configure health checks, and discover services dynamically for microservices architectures.

You can either run the automated script `cloudmap-service-discovery.sh` to execute all operations automatically with comprehensive error handling and resource cleanup, or follow the step-by-step instructions in the `cloudmap-service-discovery.md` tutorial to understand each AWS CLI command and concept in detail. The script includes interactive prompts and built-in safeguards, while the tutorial provides detailed explanations of features and best practices.

## Resources Created

The script creates the following AWS resources in order:

- Service Discovery public dns namespace
- Service Discovery service
- Service Discovery service (b)
- Service Discovery instance
- Service Discovery instance (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.