# Getting started with Amazon S3 using the AWS CLI

This tutorial guides you through the basic operations of Amazon S3 using the AWS Command Line Interface (AWS CLI). You'll learn how to create buckets, upload and download objects, organize your data, and clean up resources.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. Basic familiarity with command line interfaces.

3. Permissions to create and manage S3 resources in your AWS account.

## Create your first S3 bucket

Amazon S3 stores data as objects within containers called buckets. Each bucket must have a globally unique name across all of AWS.

First, let's generate a unique bucket name and determine your AWS region:

```
BUCKET_NAME="amzn-s3-demo-$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1)"
REGION=$(aws configure get region)
REGION=${REGION:-us-east-1}

echo "Using bucket name: $BUCKET_NAME"
echo "Using region: $REGION"
```

Now, create your bucket. The command varies slightly depending on your region:

```
# For us-east-1 region
aws s3api create-bucket --bucket "$BUCKET_NAME"

# For all other regions
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --create-bucket-configuration LocationConstraint="$REGION"
```

The output shows the location URL of your new bucket:

```
{
    "Location": "http://amzn-s3-demo-abcd1234abcd.s3.amazonaws.com/"
}
```

## Upload an object

Now that your bucket is created, let's upload a file. First, create a sample text file:

```
echo "Hello, Amazon S3! This is a sample file for the getting started tutorial." > sample.txt
```

Upload this file to your bucket:

```
aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "sample.txt"
```

The response includes an ETag (entity tag) that uniquely identifies the content of the object:

```
{
    "ETag": "\"abcd1234abcd1234abcd1234abcd1234\""
}
```

## Download and verify objects

To download an object from your bucket to your local machine:

```
aws s3api get-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    "downloaded-sample.txt"
```

The command downloads the object and saves it as `downloaded-sample.txt` in your current directory. The output provides metadata about the object:

```
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-01-13T20:39:53+00:00",
    "ContentLength": 75,
    "ETag": "\"abcd1234abcd1234abcd1234abcd1234\"",
    "ContentType": "binary/octet-stream",
    "Metadata": {}
}
```

## Copy an object to a folder prefix

Although S3 is a flat object store, you can simulate folders by using key name prefixes. Let's copy the sample file into a `backup/` prefix:

```
aws s3api copy-object \
    --bucket "$BUCKET_NAME" \
    --copy-source "$BUCKET_NAME/sample.txt" \
    --key "backup/sample.txt"
```

The response includes information about the copy operation:

```
{
    "CopyObjectResult": {
        "ETag": "\"abcd1234abcd1234abcd1234abcd1234\"",
        "LastModified": "2026-01-13T20:39:59+00:00"
    }
}
```

## Enable versioning

Versioning helps protect against accidental deletion by keeping multiple variants of an object in the same bucket.

```
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
```

With versioning enabled, uploading a file with the same key creates a new version instead of overwriting the original. Let's upload a second version of the sample file:

```
echo "Hello, Amazon S3! This is version 2 of the sample file." > sample.txt

aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "sample.txt"
```

The response now includes a `VersionId`:

```
{
    "ETag": "\"abcd1234abcd1234abcd1234abcd1234\"",
    "VersionId": "abcdxmpl1234abcd1234abcd1234abcd"
}
```

## Configure default encryption

Default encryption ensures that all objects stored in the bucket are encrypted at rest using server-side encryption with Amazon S3 managed keys (SSE-S3):

```
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'
```

## Block public access

Blocking public access is a security best practice that prevents objects in your bucket from being made public:

```
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
```

## Add tags to your bucket

Tags help you categorize your AWS resources for cost allocation, access control, and organization:

```
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {
                "Key": "Environment",
                "Value": "Tutorial"
            },
            {
                "Key": "Project",
                "Value": "S3-GettingStarted"
            }
        ]
    }'
```

Verify the tags were applied:

```
aws s3api get-bucket-tagging \
    --bucket "$BUCKET_NAME"
```

```
{
    "TagSet": [
        {
            "Key": "Environment",
            "Value": "Tutorial"
        },
        {
            "Key": "Project",
            "Value": "S3-GettingStarted"
        }
    ]
}
```

## List objects and versions

List all objects in the bucket to see your folder structure:

```
aws s3api list-objects-v2 \
    --bucket "$BUCKET_NAME"
```

Since versioning is enabled, you can also list all versions of objects in the bucket. This shows both the current and previous versions of `sample.txt`:

```
aws s3api list-object-versions \
    --bucket "$BUCKET_NAME"
```

## Clean up resources

When you're finished with this tutorial, you should delete the resources to avoid incurring charges.

For buckets with versioning enabled, you need to delete all object versions before you can delete the bucket:

```
# Delete all object versions
aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --query "Versions[].{Key:Key,VersionId:VersionId}" \
    --output text | while IFS=$'\t' read -r KEY VERSION_ID; do
    if [ -n "$KEY" ] && [ "$KEY" != "None" ]; then
        aws s3api delete-object \
            --bucket "$BUCKET_NAME" \
            --key "$KEY" \
            --version-id "$VERSION_ID"
    fi
done

# Delete all delete markers
aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" \
    --output text | while IFS=$'\t' read -r KEY VERSION_ID; do
    if [ -n "$KEY" ] && [ "$KEY" != "None" ]; then
        aws s3api delete-object \
            --bucket "$BUCKET_NAME" \
            --key "$KEY" \
            --version-id "$VERSION_ID"
    fi
done
```

After deleting all object versions, you can delete the bucket:

```
aws s3api delete-bucket --bucket "$BUCKET_NAME"
```

Don't forget to clean up local files:

```
rm -f sample.txt downloaded-sample.txt
```

## Next steps

Now that you've learned the basics of Amazon S3 with the AWS CLI, you can explore more advanced features:

1. **Access Control** – Learn about [S3 bucket policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html) and [IAM policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html) to control access to your resources.

2. **Lifecycle Management** – Configure [lifecycle rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html) to automatically transition objects to lower-cost storage classes or delete them after a specified time.

3. **Static Website Hosting** – Host a [static website](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html) on Amazon S3.

4. **Event Notifications** – Set up [event notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html) to trigger AWS Lambda functions or send messages to Amazon SNS or SQS when objects are created or deleted.

5. **Cross-Region Replication** – Configure [replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html) to automatically copy objects across different AWS Regions.

For more information about available AWS CLI commands for S3, see the [AWS CLI Command Reference for S3](https://docs.aws.amazon.com/cli/latest/reference/s3/) and [S3API](https://docs.aws.amazon.com/cli/latest/reference/s3api/).

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.