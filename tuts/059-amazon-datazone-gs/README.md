# Amazon DataZone getting started tutorial

This tutorial provides a comprehensive introduction to Amazon DataZone using the AWS CLI. You'll learn how to create data domains, set up data governance policies, catalog data assets, and enable secure data sharing and collaboration across your organization.

You can either run the provided shell script to automatically set up your Amazon DataZone domain and basic data governance infrastructure, or follow the step-by-step instructions in the tutorial markdown file to understand each component and customize the configuration for your specific data management and governance requirements.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- IAM role policy (b)
- IAM role policy (c)
- IAM role policy (d)
- DataZone domain
- DataZone project
- DataZone project (b)
- DataZone environment profile
- DataZone environment
- Glue database
- IAM role (b)
- IAM role policy (e)
- DataZone data source
- DataZone form type
- DataZone asset type
- DataZone asset
- DataZone listing change set
- DataZone subscription request

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.