# Amazon DocumentDB getting started

This tutorial demonstrates how to get started with Amazon DocumentDB by creating a MongoDB-compatible database cluster, connecting to the database, and performing basic document operations.

You can run the shell script to automatically set up the Amazon DocumentDB cluster and resources, or follow the step-by-step instructions in the tutorial to manually configure your document database environment.

## Resources Created

The script creates the following AWS resources in order:

- Secrets Manager secret
- Docdb db subnet group
- Docdb db cluster
- Docdb db instance

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.