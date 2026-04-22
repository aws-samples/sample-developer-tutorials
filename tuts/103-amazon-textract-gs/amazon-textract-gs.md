# Extract text from documents with Amazon Textract

This tutorial shows you how to upload a document image to Amazon S3, use Amazon Textract to detect text and analyze the document for forms and tables, and detect text directly from local file bytes.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Python 3 installed (used to generate a sample PNG image)
- Permissions for `s3:CreateBucket`, `s3:PutObject`, `s3:DeleteObject`, `s3:DeleteBucket`, `textract:DetectDocumentText`, and `textract:AnalyzeDocument`

## Step 1: Use the sample document image

This tutorial includes a sample document image at `../../sample-images/sample-document.png`. Copy it to your working directory:

```
cp ../../sample-images/sample-document.png sample.png
```

## Step 2: Detect text from local file bytes

Send the document directly as base64-encoded bytes instead of referencing S3.

```bash
aws textract detect-document-text \
    --document '{"Bytes":"'"$(base64 -w0 "$WORK_DIR/sample.png")"'"}' \
    --query '{Pages:DocumentMetadata.Pages,BlockCount:Blocks|length(@)}' --output table
```

The `Bytes` option is useful for quick tests or when you don't want to upload to S3 first. The document size limit for synchronous operations is 10 MB.

## Step 3: Upload to S3 (alternative method)

If you want to use S3 instead of local file bytes, upload the image to a bucket. If the tutorial prereq bucket stack is deployed, use that bucket. Otherwise create one.


Create an S3 bucket and upload the sample image.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
RANDOM_ID=$(openssl rand -hex 4)
BUCKET_NAME="textract-tut-${RANDOM_ID}-${ACCOUNT_ID}"

aws s3api create-bucket --bucket "$BUCKET_NAME" \
    --create-bucket-configuration LocationConstraint="$AWS_DEFAULT_REGION"
aws s3 cp "$WORK_DIR/sample.png" "s3://$BUCKET_NAME/sample.png" --quiet
echo "Uploaded to s3://$BUCKET_NAME/sample.png"
```

Textract reads documents directly from S3. For `us-east-1`, omit the `--create-bucket-configuration` parameter.

## Step 4: Detect text from S3 in the document

```bash
aws textract detect-document-text \
    --document '{"S3Object":{"Bucket":"'"$BUCKET_NAME"'","Name":"sample.png"}}' \
    --query 'Blocks[?BlockType==`LINE`].{Text:Text,Confidence:Confidence}' --output table
```

`detect-document-text` returns `LINE` and `WORD` blocks. Each block includes the detected text and a confidence score. With the blank sample image, no text lines are returned.

## Step 5: Analyze document for forms and tables

```bash
aws textract analyze-document \
    --document '{"S3Object":{"Bucket":"'"$BUCKET_NAME"'","Name":"sample.png"}}' \
    --feature-types '["FORMS","TABLES"]' \
    --query '{Pages:DocumentMetadata.Pages,Blocks:Blocks|length(@)}' --output table
```

`analyze-document` goes beyond text detection. With `FORMS`, it identifies key-value pairs (like form fields). With `TABLES`, it identifies rows and columns. You can request both features in a single call.

## Cleanup

Delete the S3 bucket and its contents, then remove the temporary directory.

```bash
aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet
aws s3 rb "s3://$BUCKET_NAME"
rm -rf "$WORK_DIR"
```

The script automates all steps including cleanup:

```bash
bash amazon-textract-gs.sh
```

## Related resources

- [Getting started with Amazon Textract](https://docs.aws.amazon.com/textract/latest/dg/getting-started.html)
- [Detecting text](https://docs.aws.amazon.com/textract/latest/dg/detecting-document-text.html)
- [Analyzing documents](https://docs.aws.amazon.com/textract/latest/dg/analyzing-document-text.html)
- [Amazon Textract quotas](https://docs.aws.amazon.com/textract/latest/dg/limits.html)
