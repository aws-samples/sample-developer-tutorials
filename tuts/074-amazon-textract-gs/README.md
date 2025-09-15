# Amazon Textract getting started

This tutorial demonstrates how to get started with Amazon Textract, a machine learning service that automatically extracts text, handwriting, and data from scanned documents. You'll learn how to use Amazon Textract to analyze documents and extract key information using both synchronous and asynchronous operations.

You can either run the provided shell script (`amazon-textract-getting-started.sh`) for an automated walkthrough of the key features, or follow the step-by-step instructions in the tutorial (`amazon-textract-getting-started.md`) to manually explore Amazon Textract's capabilities at your own pace.

## Resources Created

The script creates the following AWS resources in order:

- S3 bucket (for document storage)
- Textract document analysis job

The script prompts you to clean up resources when you run it, including if there's an error part way through. If you need to clean up resources later, you can use the script log as a reference point for which resources were created.