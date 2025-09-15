# Amazon Redshift serverless

This tutorial demonstrates how to set up and use Amazon Redshift Serverless, a serverless data warehouse service that automatically scales compute capacity and eliminates the need to manage infrastructure.

You can either run the automated script `redshift-serverless.sh` to execute all the steps automatically, or follow the step-by-step instructions in the `redshift-serverless.md` tutorial to understand each operation in detail.

## Resources Created

The script creates the following AWS resources in order:

- Secrets Manager secret
- IAM role
- IAM role (b)
- IAM role policy
- IAM role policy (b)
- Redshift-Serverless namespace
- Redshift-Serverless namespace (b)
- Redshift-Serverless workgroup
- Redshift-Serverless workgroup (b)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.