# Extract text from documents with Amazon Textract

This tutorial shows you how to upload a document image to Amazon S3, use Amazon Textract to detect text and analyze the document for forms and tables, and detect text directly from local file bytes.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Python 3 installed (used to generate a sample PNG image)
- Permissions for `s3:CreateBucket`, `s3:PutObject`, `s3:DeleteObject`, `s3:DeleteBucket`, `textract:DetectDocumentText`, and `textract:AnalyzeDocument`

## Step 1: Create a sample document image

Generate a minimal PNG image to use as a test document. In practice, you would use a scanned document or photograph containing text.

```bash
WORK_DIR=$(mktemp -d)

python3 -c "
import struct, zlib
w,h=200,50
row=b'\x00'+b'\xff\xff\xff'*w
raw=row*h
comp=zlib.compress(raw)
def ch(t,d):
    c=t+d
    return struct.pack('>I',len(d))+c+struct.pack('>I',zlib.crc32(c)&0xffffffff)
with open('$WORK_DIR/sample.png','wb') as f:
    f.write(b'\x89PNG\r\n\x1a\n')
    f.write(ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0)))
    f.write(ch(b'IDAT',comp))
    f.write(ch(b'IEND',b''))
"
echo "Created sample.png (200x50 white image)"
```

This creates a blank white PNG. Textract won't find text in it, but it demonstrates the API calls. Replace it with a real document to see text extraction in action.

## Step 2: Upload the document to S3

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

## Step 3: Detect text in the document

```bash
aws textract detect-document-text \
    --document '{"S3Object":{"Bucket":"'"$BUCKET_NAME"'","Name":"sample.png"}}' \
    --query 'Blocks[?BlockType==`LINE`].{Text:Text,Confidence:Confidence}' --output table
```

`detect-document-text` returns `LINE` and `WORD` blocks. Each block includes the detected text and a confidence score. With the blank sample image, no text lines are returned.

## Step 4: Analyze document for forms and tables

```bash
aws textract analyze-document \
    --document '{"S3Object":{"Bucket":"'"$BUCKET_NAME"'","Name":"sample.png"}}' \
    --feature-types '["FORMS","TABLES"]' \
    --query '{Pages:DocumentMetadata.Pages,Blocks:Blocks|length(@)}' --output table
```

`analyze-document` goes beyond text detection. With `FORMS`, it identifies key-value pairs (like form fields). With `TABLES`, it identifies rows and columns. You can request both features in a single call.

## Step 5: Detect text from local file bytes

Send the document directly as base64-encoded bytes instead of referencing S3.

```bash
aws textract detect-document-text \
    --document '{"Bytes":"'"$(base64 -w0 "$WORK_DIR/sample.png")"'"}' \
    --query '{Pages:DocumentMetadata.Pages,BlockCount:Blocks|length(@)}' --output table
```

The `Bytes` option is useful for quick tests or when you don't want to upload to S3 first. The document size limit for synchronous operations is 10 MB.

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
