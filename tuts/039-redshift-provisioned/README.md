# Amazon Redshift provisioned

This tutorial demonstrates how to set up Amazon Redshift provisioned clusters for data warehousing, including creating clusters, loading sample data, and running analytical queries on large datasets.

You can run the shell script to automatically provision the Amazon Redshift cluster and load sample data, or follow the step-by-step instructions in the tutorial to manually configure your data warehouse environment.

## Resources Created

The script creates the following AWS resources in order:

- Redshift cluster
- IAM role
- IAM role policy

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.