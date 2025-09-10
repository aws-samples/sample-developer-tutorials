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
BUCKET_NAME="demo-s3-bucket-$(openssl rand -hex 6)"
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
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
```

The output shows the location URL of your new bucket:

```
{
    "Location": "http://demo-s3-bucket-abcd1234.s3.amazonaws.com/"
}
```

After creating your bucket, it's important to configure security settings. Let's apply some best practices:

**Block public access (recommended for security)**

```
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

**Enable versioning (helps protect against accidental deletion)**

```
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
```

**Set default encryption (protects your data at rest)**

```
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
```

## Upload objects to your bucket

Now that your bucket is configured, let's upload some files. First, create a sample text file:

```
echo "This is a sample file for the S3 tutorial." > sample-file.txt
```

Upload this file to your bucket:

```
aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample-file.txt" \
    --body "sample-file.txt"
```

The response includes an ETag (entity tag) that uniquely identifies the content of the object, and since we enabled encryption, it also shows the encryption method:

```
{
    "ETag": "\"4f4cf806569737e1f3ea064a1d4813db\"",
    "ServerSideEncryption": "AES256",
    "VersionId": "9RCg6lFF_CmB.r_YlMS8sdPBiv878gQI"
}
```

You can also upload files with additional metadata. Let's create another file and add some metadata to it:

```
echo "This is a document with metadata." > sample-document.txt

aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "documents/sample-document.txt" \
    --body "sample-document.txt" \
    --content-type "text/plain" \
    --metadata "author=AWSDocumentation,purpose=tutorial"
```

Notice that we used `documents/` in the key name. This creates a logical folder structure in your bucket, even though S3 is actually a flat object store.

## Download and verify objects

To download an object from your bucket to your local machine:

```
aws s3api get-object \
    --bucket "$BUCKET_NAME" \
    --key "sample-file.txt" \
    "downloaded-sample-file.txt"
```

The command downloads the object and saves it as `downloaded-sample-file.txt` in your current directory. The output provides metadata about the object:

```
{
    "AcceptRanges": "bytes",
    "LastModified": "Thu, 22 May 2025 20:39:53 GMT",
    "ContentLength": 43,
    "ETag": "\"4f4cf806569737e1f3ea064a1d4813db\"",
    "VersionId": "9RCg6lFF_CmB.r_YlMS8sdPBiv878gQI",
    "ContentType": "binary/octet-stream",
    "ServerSideEncryption": "AES256",
    "Metadata": {}
}
```

If you just want to check if an object exists or view its metadata without downloading it:

```
aws s3api head-object \
    --bucket "$BUCKET_NAME" \
    --key "sample-file.txt"
```

This returns the same metadata information without transferring the actual object content.

## Organize objects with folders

Although S3 is a flat object store, you can simulate folders by using key name prefixes. Let's create a folder structure and copy an existing object into it.

First, create a folder by uploading an empty object with a trailing slash:

```
touch empty-file.tmp
aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "favorite-files/" \
    --body empty-file.tmp
```

Now, copy the sample file into this folder:

```
aws s3api copy-object \
    --bucket "$BUCKET_NAME" \
    --copy-source "$BUCKET_NAME/sample-file.txt" \
    --key "favorite-files/sample-file.txt"
```

The response includes information about the copy operation:

```
{
    "CopySourceVersionId": "9RCg6lFF_CmB.r_YlMS8sdPBiv878gQI",
    "VersionId": "rBtZnoxd0V6rPxUPDUYmPz1CzRXbIIS7",
    "ServerSideEncryption": "AES256",
    "CopyObjectResult": {
        "ETag": "\"4f4cf806569737e1f3ea064a1d4813db\"",
        "LastModified": "2025-05-22T20:39:59.000Z"
    }
}
```

Let's list all objects in the bucket to see our folder structure:

```
aws s3api list-objects-v2 \
    --bucket "$BUCKET_NAME" \
    --query 'Contents[].Key' \
    --output table
```

The output shows all objects, including our folder structure:

```
------------------------------------
|           ListObjectsV2          |
+----------------------------------+
|  documents/sample-document.txt   |
|  favorite-files/                 |
|  favorite-files/sample-file.txt  |
|  sample-file.txt                 |
+----------------------------------+
```

You can also list objects within a specific folder:

```
aws s3api list-objects-v2 \
    --bucket "$BUCKET_NAME" \
    --prefix "favorite-files/" \
    --query 'Contents[].Key' \
    --output table
```

This shows only the objects within the "favorite-files" folder:

```
------------------------------------
|           ListObjectsV2          |
+----------------------------------+
|  favorite-files/                 |
|  favorite-files/sample-file.txt  |
+----------------------------------+
```

## Add tags to your bucket

Tags help you categorize your AWS resources for cost allocation, access control, and organization:

```
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[{Key=Project,Value=S3Tutorial},{Key=Environment,Value=Demo}]'
```

## Clean up resources

When you're finished with this tutorial, you should delete the resources to avoid incurring charges.

For buckets with versioning enabled, you need to delete all object versions before you can delete the bucket:

```
# Delete all object versions
VERSIONS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json)
if [ -n "$VERSIONS" ] && [ "$VERSIONS" != "null" ]; then
    echo "{\"Objects\": $VERSIONS}" > versions.json
    aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file://versions.json
    rm versions.json
fi

# Delete all delete markers
MARKERS=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json)
if [ -n "$MARKERS" ] && [ "$MARKERS" != "null" ]; then
    echo "{\"Objects\": $MARKERS}" > markers.json
    aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file://markers.json
    rm markers.json
fi
```

After deleting all object versions, you can delete the bucket:

```
aws s3api delete-bucket --bucket "$BUCKET_NAME"
```

Don't forget to clean up local files:

```
rm -f sample-file.txt sample-document.txt downloaded-sample-file.txt empty-file.tmp
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