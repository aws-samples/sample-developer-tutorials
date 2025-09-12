# Amazon RDS getting started

This tutorial demonstrates how to get started with Amazon Relational Database Service (Amazon RDS) by creating a managed database instance, connecting to the database, and performing basic database operations.

You can run the shell script to automatically provision the Amazon RDS database instance and configure security settings, or follow the step-by-step instructions in the tutorial to manually set up your relational database environment.

## Resources Created

The script creates the following AWS resources in order:

- EC2 security group
- EC2 security group (b)
- RDS db subnet group
- RDS db subnet group (b)
- Secrets Manager secret
- Secrets Manager secret (b)
- RDS db instance
- RDS db instance (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.