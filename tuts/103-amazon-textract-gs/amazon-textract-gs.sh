#!/bin/bash
# Tutorial: Extract text from documents with Amazon Textract
# Source: https://docs.aws.amazon.com/textract/latest/dg/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/textract-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
BUCKET_NAME="textract-tut-${RANDOM_ID}-${ACCOUNT_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
        aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null && echo "  Deleted bucket $BUCKET_NAME"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a sample document image
echo "Step 1: Creating a sample document image"
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
echo "  Created sample.png (200x50 white image)"

# Step 2: Create S3 bucket and upload
echo "Step 2: Uploading document to S3"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi
aws s3 cp "$WORK_DIR/sample.png" "s3://$BUCKET_NAME/sample.png" --quiet
echo "  Uploaded to s3://$BUCKET_NAME/sample.png"

# Step 3: Detect text in the document
echo "Step 3: Detecting text in document"
aws textract detect-document-text \
    --document "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --query 'Blocks[?BlockType==`LINE`].{Text:Text,Confidence:Confidence}' --output table 2>/dev/null || \
    echo "  No text detected (expected — the sample image is blank)"

# Step 4: Analyze document (forms and tables)
echo "Step 4: Analyzing document for forms and tables"
aws textract analyze-document \
    --document "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --feature-types '["FORMS","TABLES"]' \
    --query '{Pages:DocumentMetadata.Pages,Blocks:Blocks|length(@)}' --output table

# Step 5: Detect text using bytes (inline)
echo "Step 5: Detecting text from local file (bytes)"
aws textract detect-document-text \
    --document "{\"Bytes\":\"$(base64 -w0 "$WORK_DIR/sample.png")\"}" \
    --query '{Pages:DocumentMetadata.Pages,BlockCount:Blocks|length(@)}' --output table

echo ""
echo "Tutorial complete."
echo "Note: The sample image is blank, so no text was detected."
echo "Try with a real document image to see Textract extract text, forms, and tables."
echo ""
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive && aws s3 rb s3://$BUCKET_NAME"
fi
