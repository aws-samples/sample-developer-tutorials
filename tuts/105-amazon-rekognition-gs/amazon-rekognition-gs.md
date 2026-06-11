# Detect labels in images with Amazon Rekognition

## Overview

In this tutorial, you use the AWS CLI to analyze images with Amazon Rekognition. You create a sample PNG image, upload it to S3, detect labels, detect labels from local bytes, detect text, and detect image properties. You then clean up the S3 bucket.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `rekognition:DetectLabels`, `rekognition:DetectText`, `s3:CreateBucket`, `s3:PutObject`, `s3:DeleteObject`, and `s3:DeleteBucket`.

## Step 1: Use the sample image

This tutorial includes a sample photo at `../../sample-images/sample-photo.png`. Copy it to your working directory:

```
cp ../../sample-images/sample-photo.png sample.png
```

## Step 2: Upload to S3

Create an S3 bucket and upload the image.

```bash
RANDOM_ID=$(openssl rand -hex 4)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="rekognition-tut-${RANDOM_ID}-${ACCOUNT_ID}"

aws s3api create-bucket --bucket "$BUCKET_NAME"
aws s3 cp sample.png "s3://$BUCKET_NAME/sample.png"
```

For regions other than `us-east-1`, add `--create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION`.

## Step 3: Detect labels

Detect labels in the image stored in S3.

```bash
aws rekognition detect-labels \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --max-labels 10 \
    --query 'Labels[].{Label:Name,Confidence:Confidence}' --output table
```

Rekognition returns labels with confidence scores. For a gradient image, expect generic labels like "Pattern" or "Art".

## Step 4: Detect labels from local bytes

Pass the image directly from the local filesystem instead of S3.

```bash
aws rekognition detect-labels \
    --image-bytes "fileb://sample.png" \
    --max-labels 5 \
    --query 'Labels[:5].{Label:Name,Confidence:Confidence}' --output table
```

The `fileb://` prefix sends the file as raw bytes. This avoids the S3 upload step for quick tests.

## Step 5: Detect text in image

Look for text in the image.

```bash
aws rekognition detect-text \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --query 'TextDetections[:5].{Text:DetectedText,Type:Type,Confidence:Confidence}' --output table
```

The gradient image contains no text, so this returns an empty result. With a real image containing text, Rekognition returns each detected word and line.

## Step 6: Detect image properties

Use the `IMAGE_PROPERTIES` feature to get dominant colors and quality metrics.

```bash
aws rekognition detect-labels \
    --image "{\"S3Object\":{\"Bucket\":\"$BUCKET_NAME\",\"Name\":\"sample.png\"}}" \
    --features GENERAL_LABELS IMAGE_PROPERTIES \
    --query 'ImageProperties.{Quality:Quality,DominantColors:DominantColors[:3]}' --output json
```

Image properties include sharpness, brightness, and dominant colors.

## Cleanup

Delete the S3 bucket and its contents.

```bash
aws s3 rm "s3://$BUCKET_NAME" --recursive
aws s3 rb "s3://$BUCKET_NAME"
```

The script automates all steps including cleanup:

```bash
bash amazon-rekognition-gs.sh
```

## Related resources

- [Getting started with Amazon Rekognition](https://docs.aws.amazon.com/rekognition/latest/dg/getting-started.html)
- [Detecting labels](https://docs.aws.amazon.com/rekognition/latest/dg/labels-detect-labels-image.html)
- [Detecting text](https://docs.aws.amazon.com/rekognition/latest/dg/text-detecting-text-procedure.html)
- [Image properties](https://docs.aws.amazon.com/rekognition/latest/dg/image-properties.html)
