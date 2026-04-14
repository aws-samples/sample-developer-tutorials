#!/bin/bash
# Tutorial: Detect labels in images with Amazon Rekognition
# Source: https://docs.aws.amazon.com/rekognition/latest/dg/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/rekognition-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
BUCKET_NAME="rekognition-tut-${RANDOM_ID}-${ACCOUNT_ID}"

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

# Step 1: Create a sample image (simple colored PNG)
echo "Step 1: Creating sample image"
python3 -c "
import struct, zlib
w,h=100,100
# Blue/green gradient - gives Rekognition something to analyze
rows=b''
for y in range(h):
    rows+=b'\x00'  # filter byte
    for x in range(w):
        rows+=bytes([int(x*2.55), int(y*2.55), 128])
comp=zlib.compress(rows)
def ch(t,d):
    c=t+d
    return struct.pack('>I',len(d))+c+struct.pack('>I',zlib.crc32(c)&0xffffffff)
with open('$WORK_DIR/sample.png','wb') as f:
    f.write(b'\x89PNG\r\n\x1a\n')
    f.write(ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0)))
    f.write(ch(b'IDAT',comp))
    f.write(ch(b'IEND',b''))
"
echo "  Created sample.png (100x100 gradient)"

# Step 2: Upload to S3
echo "Step 2: Uploading to S3"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi
aws s3 cp "$WORK_DIR/sample.png" "s3://$BUCKET_NAME/sample.png" --quiet
echo "  Uploaded to s3://$BUCKET_NAME/sample.png"

# Step 3: Detect labels
echo "Step 3: Detecting labels in image"
aws rekognition detect-labels \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --max-labels 10 \
    --query 'Labels[].{Label:Name,Confidence:Confidence}' --output table

# Step 4: Detect labels from bytes (local file)
echo "Step 4: Detecting labels from local file"
aws rekognition detect-labels \
    --image-bytes "fileb://$WORK_DIR/sample.png" \
    --max-labels 5 \
    --query 'Labels[:5].{Label:Name,Confidence:Confidence}' --output table

# Step 5: Detect text in image
echo "Step 5: Detecting text in image"
aws rekognition detect-text \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --query 'TextDetections[:5].{Text:DetectedText,Type:Type,Confidence:Confidence}' --output table 2>/dev/null || \
    echo "  No text detected (expected — the sample is a gradient)"

# Step 6: Detect image properties
echo "Step 6: Detecting image properties"
aws rekognition detect-labels \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --features GENERAL_LABELS IMAGE_PROPERTIES \
    --query 'ImageProperties.{Quality:Quality,DominantColors:DominantColors[:3]}' --output json 2>/dev/null | python3 -m json.tool 2>/dev/null || \
    echo "  Image properties not available for this image"

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive && aws s3 rb s3://$BUCKET_NAME"
fi
