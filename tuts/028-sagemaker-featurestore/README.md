# Amazon SageMaker Feature Store

This tutorial demonstrates how to use Amazon SageMaker Feature Store to create, manage, and serve machine learning features for training and inference, including feature group creation and data ingestion.

You can run the shell script to automatically set up the SageMaker Feature Store resources and ingest sample features, or follow the step-by-step instructions in the tutorial to manually configure your feature management infrastructure.

## Resources Created

The script creates the following AWS resources in order:

- IAM role
- IAM role policy
- IAM role policy (b)
- S3 bucket
- S3 bucket (b)
- S3 public access block
- SageMaker feature group
- SageMaker feature group (b)
- Sagemaker-Featurestore-Runtime record
- Sagemaker-Featurestore-Runtime record (b)
- Sagemaker-Featurestore-Runtime record (c)
- Sagemaker-Featurestore-Runtime record (d)

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.