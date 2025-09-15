# Amazon EMR getting started

This tutorial demonstrates how to get started with Amazon EMR by creating a managed Hadoop cluster, submitting big data processing jobs, and analyzing large datasets using popular frameworks like Spark and Hive.

You can run the shell script to automatically provision the Amazon EMR cluster and submit sample jobs, or follow the step-by-step instructions in the tutorial to manually set up your big data processing environment.

## Resources Created

The script creates the following AWS resources in order:

- EMR default roles
- EC2 key pair
- EMR cluster

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.