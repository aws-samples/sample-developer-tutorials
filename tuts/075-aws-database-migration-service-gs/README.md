# AWS Database Migration Service getting started tutorial

This tutorial provides a comprehensive introduction to AWS Database Migration Service (DMS) using the AWS CLI. You'll learn how to set up migration tasks, configure source and target endpoints, and migrate databases from on-premises or other cloud environments to AWS with minimal downtime.

You can either run the provided shell script to automatically set up your DMS replication instance and basic migration configuration, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the migration setup for your specific database migration requirements.

## Resources Created

The script creates the following AWS resources in order:

- Secrets Manager secret
- EC2 vpc
- EC2 subnet
- EC2 subnet (b)
- EC2 subnet (c)
- EC2 subnet (d)
- EC2 internet gateway
- EC2 internet gateway (b)
- EC2 route table
- EC2 route
- EC2 route table (b)
- EC2 route table (c)
- RDS db parameter group
- RDS db parameter group (b)
- RDS db subnet group
- RDS db instance
- RDS db instance (b)
- EC2 key pair
- EC2 instances
- Database Migration Service replication subnet group

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.