# Getting started with Amazon Textract using the AWS CLI

This tutorial guides you through using Amazon Textract to analyze document text using the AWS Command Line Interface (AWS CLI). You'll learn how to set up the necessary resources, upload a document to Amazon S3, analyze the document with Amazon Textract, and interpret the results.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. An AWS account with permissions to use Amazon Textract and Amazon S3 (`AmazonTextractFullAccess` and `AmazonS3ReadOnlyAccess`).
2. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
3. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
4. A document image (PNG, JPEG, PDF, or TIFF format) that you want to analyze.

### Cost Considerations

This tutorial uses AWS services that will incur small charges:

- **Amazon Textract**: Approximately $0.0045 for analyzing one page with tables, forms, and signatures detection
- **Amazon S3**: Minimal charges (less than $0.0001) for storage and requests

Total estimated cost: Less than $0.01 for completing this tutorial once.

The cleanup instructions at the end will help you remove all resources to prevent ongoing charges.

## Create an S3 bucket

Amazon Textract can analyze documents stored in Amazon S3. In this step, you'll create an S3 bucket to store your document.

**Create a new S3 bucket**

The following command creates a new S3 bucket with a unique name. Replace the example bucket name with a globally unique bucket name of your own.

```
BUCKET_NAME="amzn-s3-demo-bucket"
aws s3 mb "s3://$BUCKET_NAME"
```

After running this command, you should see output confirming that the bucket was created:

```
make_bucket: amzn-s3-demo-bucket
```

By default, S3 buckets are private and secure.

## Upload a document to S3

Now that you have a bucket, you'll upload a document to analyze. Amazon Textract supports various document formats including PNG, JPEG, PDF, and TIFF.

**Upload your document to S3**

The following command uploads your document to the S3 bucket you created. Replace the example document name with the path to your own document.

```
DOCUMENT_NAME="example-document.png"
aws s3 cp "./$DOCUMENT_NAME" "s3://$BUCKET_NAME/"
```

After running this command, you should see output confirming that the file was uploaded:

```
upload: ./document.png to s3://amzn-s3-demo-bucket/example-document.png
```

## Analyze the document with Amazon Textract

Now that your document is stored in S3, you can use Amazon Textract to analyze it. Amazon Textract can extract text, forms, tables, and signatures from documents.

**Create parameter files for the Textract command**

To avoid shell escaping issues, let's create JSON files for the command parameters:

```
cat > document.json << EOF
{
  "S3Object": {
    "Bucket": "$BUCKET_NAME",
    "Name": "$DOCUMENT_NAME"
  }
}
EOF

cat > features.json << EOF
["TABLES","FORMS","SIGNATURES"]
EOF
```

These files define the S3 location of your document and the features you want Amazon Textract to detect.

**Analyze the document**

The following command analyzes the document using Amazon Textract:

```
aws textract analyze-document --document file://document.json --feature-types file://features.json > textract-analysis-results.json
```

This command sends the document to Amazon Textract for analysis and saves the results to a file named `textract-analysis-results.json`. The analysis might take a few seconds to complete.

## Understand the analysis results

Amazon Textract returns a detailed JSON response containing all the information extracted from your document. Let's examine the key components of these results.

**View document metadata**

The following command extracts the number of pages in the document:

```
grep -o '"Pages": [0-9]*' textract-analysis-results.json | awk '{print $2}'
```

This will output the number of pages in your document.

**Count detected elements**

The following commands count the different types of elements detected in your document:

```
echo "Total blocks detected: $(grep -o '"BlockType":' textract-analysis-results.json | wc -l)"
echo "Pages: $(grep -o '"BlockType": "PAGE"' textract-analysis-results.json | wc -l)"
echo "Lines of text: $(grep -o '"BlockType": "LINE"' textract-analysis-results.json | wc -l)"
echo "Words: $(grep -o '"BlockType": "WORD"' textract-analysis-results.json | wc -l)"
echo "Tables: $(grep -o '"BlockType": "TABLE"' textract-analysis-results.json | wc -l)"
echo "Table cells: $(grep -o '"BlockType": "CELL"' textract-analysis-results.json | wc -l)"
echo "Key-value pairs: $(grep -o '"BlockType": "KEY_VALUE_SET"' textract-analysis-results.json | wc -l)"
echo "Signatures: $(grep -o '"BlockType": "SIGNATURE"' textract-analysis-results.json | wc -l)"
```

These commands will show you counts of the different elements detected in your document, such as lines of text, words, tables, and forms.
```
Total blocks detected: 324
Pages: 1
Lines of text: 79
Words: 179
Tables: 1
Table cells: 30
Key-value pairs: 32
Signatures: 0
```

**Understanding block types**

Amazon Textract organizes the extracted information into "blocks" of different types:

- **PAGE**: Represents a page in the document
- **LINE**: A line of text
- **WORD**: A word in a line of text
- **TABLE**: A table in the document
- **CELL**: A cell within a table
- **KEY_VALUE_SET**: A key-value pair in a form
- **SELECTION_ELEMENT**: A selection element like a checkbox
- **SIGNATURE**: A signature detected in the document

Each block includes information such as the detected text, confidence score, and geometric position on the page.

## Troubleshooting

Here are solutions to common issues you might encounter:

**Permission errors**
- Ensure your AWS user has the `AmazonTextractFullAccess` and `AmazonS3ReadOnlyAccess` permissions
- Check that your AWS CLI is properly configured with valid credentials

**Unsupported document format**
- Ensure your document is in a supported format (PNG, JPEG, PDF, or TIFF)
- If using PDF, ensure it's not password-protected

**Document too large**
- For documents larger than 10MB or with many pages, use the asynchronous API instead (`start-document-analysis` and `get-document-analysis`)

**Poor text recognition**
- Ensure your document has good contrast between text and background
- Use higher resolution images for better results

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring any unnecessary charges.

**Delete the document from S3**

The following command deletes the document from your S3 bucket:

```
aws s3 rm "s3://$BUCKET_NAME/$DOCUMENT_NAME"
```

After running this command, you should see output confirming that the file was deleted:

```
delete: s3://amzn-s3-demo-bucket/example-document.png
```

**Delete the S3 bucket**

The following command deletes the S3 bucket you created:

```
aws s3 rb "s3://$BUCKET_NAME" --force
```

After running this command, you should see output confirming that the bucket was deleted:

```
remove_bucket: amzn-s3-demo-bucket
```

The `--force` option ensures that the bucket is deleted even if it's not empty.

**Delete local files**

You can also delete the local JSON files you created:

```
rm -f document.json features.json
```

The analysis results file (textract-analysis-results.json) is kept for your reference.

## Going to production

This tutorial demonstrates basic Amazon Textract functionality for educational purposes. For production environments, consider these additional best practices:

### Security considerations
- Use more specific IAM permissions instead of the broad `AmazonTextractFullAccess` policy
- Implement server-side encryption for S3 objects and Textract results
- Consider using VPC endpoints for enhanced security
- Implement proper secrets management for any credentials

### Architecture considerations
- For large documents or high volumes, use asynchronous APIs (`start-document-analysis` and `get-document-analysis`)
- Implement an event-driven architecture using S3 event notifications and AWS Lambda
- Use Amazon SQS for queuing documents to be processed
- Implement error handling with retries and dead-letter queues
- Set up monitoring and alerting with Amazon CloudWatch

For more information on building production-ready applications:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Serverless Document Processing](https://aws.amazon.com/solutions/implementations/serverless-document-processing/)

## Next steps

Now that you've learned how to use Amazon Textract with the AWS CLI, you can explore more advanced features:

- [Process large documents asynchronously](https://docs.aws.amazon.com/textract/latest/dg/async.html) using the start-document-analysis and get-document-analysis operations
- [Extract text from documents](https://docs.aws.amazon.com/textract/latest/dg/detecting-document-text.html) using the detect-document-text operation
- [Analyze expense documents](https://docs.aws.amazon.com/textract/latest/dg/expense-analysis.html) using the analyze-expense operation
- [Analyze identity documents](https://docs.aws.amazon.com/textract/latest/dg/id-analysis.html) using the analyze-id operation
- [Query documents](https://docs.aws.amazon.com/textract/latest/dg/query.html) using the Queries feature of analyze-document

You can also integrate Amazon Textract with other AWS services like Amazon Comprehend for entity recognition or Amazon Augmented AI for human review of low-confidence predictions.
