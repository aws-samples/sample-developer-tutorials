# Amazon Elastic Block Store intermediate

This tutorial demonstrates intermediate Amazon Elastic Block Store (Amazon EBS) concepts including volume types, snapshots, encryption, and performance optimization for block storage attached to EC2 instances.

You can run the shell script to automatically create and configure advanced EBS resources, or follow the step-by-step instructions in the tutorial to manually implement intermediate EBS storage solutions.

## Resources Created

The script creates the following AWS resources in order:

- EC2 volume
- EC2 snapshot
- EC2 volume (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.