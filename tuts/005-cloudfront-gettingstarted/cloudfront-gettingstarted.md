# Get started with a basic CloudFront distribution using the AWS CLI

This tutorial shows you how to use the AWS CLI to set up a basic CloudFront distribution with an Amazon S3 bucket as the origin. You'll learn how to create an S3 bucket, upload content, create a CloudFront distribution with origin access control (OAC), and access your content through CloudFront.

## Topics

- [Prerequisites](#prerequisites)
- [Create an Amazon S3 bucket](#create-an-amazon-s3-bucket)
- [Upload content to the bucket](#upload-content-to-the-bucket)
- [Create a CloudFront distribution with OAC](#create-a-cloudfront-distribution-with-oac)
- [Access your content through CloudFront](#access-your-content-through-cloudfront)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security-iam-cloudfront.html) to create and manage CloudFront and S3 resources in your AWS account.

**Cost**: Running this tutorial for approximately one hour will cost around $0.09, primarily for CloudFront data transfer. The S3 storage costs for the small files used are negligible. The tutorial includes cleanup instructions to avoid ongoing charges.

Let's get started with creating and managing CloudFront resources using the CLI.

## Create an Amazon S3 bucket

An Amazon S3 bucket is a container for files (objects) or folders. CloudFront can distribute almost any type of file when an S3 bucket is the source. In this step, you'll create an S3 bucket to store your content.

**Create a bucket**

The following command creates a new S3 bucket with a unique name. For this tutorial, replace the example bucket name with a globally unique name.

```bash
# Create an S3 bucket with a unique name
aws s3 mb s3://amzn-s3-demo-abcd1234
```

The output should look similar to:

```
make_bucket: amzn-s3-demo-abcd1234
```

This command creates a new S3 bucket in your default AWS Region.

## Upload content to the bucket

After creating your S3 bucket, you'll need to upload some content to it. For this tutorial, we'll use the sample "Hello World" webpage provided by AWS.

**Download and extract sample content**

First, download and extract the sample files:

```bash
# Create a temporary directory
mkdir -p ~/cloudfront-demo

# Download the sample hello-world files
curl -o ~/cloudfront-demo/hello-world-html.zip https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/samples/hello-world-html.zip

# Extract the zip file
unzip ~/cloudfront-demo/hello-world-html.zip -d ~/cloudfront-demo/hello-world
```

This will create a directory with an `index.html` file and a `css` folder containing the styling for the Hello World webpage.

**Upload files to your S3 bucket**

Now, upload these files to your S3 bucket:

```bash
# Upload the files to your S3 bucket
aws s3 cp ~/cloudfront-demo/hello-world/ s3://amzn-s3-demo-abcd1234/ --recursive
```

The output should show each file being uploaded:

```
upload: cloudfront-demo/hello-world/css/styles.css to s3://amzn-s3-demo-abcd1234/css/styles.css
upload: cloudfront-demo/hello-world/index.html to s3://amzn-s3-demo-abcd1234/index.html
```

The `--recursive` flag ensures that all files, including those in subdirectories, are uploaded to the bucket.

## Create a CloudFront distribution with OAC

Now that you have content in your S3 bucket, you'll create a CloudFront distribution to serve this content. You'll use origin access control (OAC) to ensure that users can only access your S3 content through CloudFront, not directly from the S3 bucket.

**Create an origin access control**

First, create an origin access control configuration:

```bash
# Create an OAC configuration
aws cloudfront create-origin-access-control \
    --origin-access-control-config Name="oac-for-s3",SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3
```

The output will include details about the newly created OAC:

```json
{
    "OriginAccessControl": {
        "Id": "E1ABCD2EFGHIJ",
        "OriginAccessControlConfig": {
            "Name": "oac-for-s3",
            "SigningProtocol": "sigv4",
            "SigningBehavior": "always",
            "OriginAccessControlOriginType": "s3"
        }
    },
    "Location": "https://cloudfront.amazonaws.com/2020-05-31/origin-access-control/E1ABCD2EFGHIJ",
    "ETag": "E1XMPLABCD123"
}
```

Save the OAC ID from the output, as you'll need it in the next step:

```bash
OAC_ID="E1ABCD2EFGHIJ"
```

**Create a CloudFront distribution**

Now, create a CloudFront distribution that uses your S3 bucket as the origin with OAC. Replace the example bucket name with your bucket name for the Id, DomainName, and TargetOriginId values.

```bash
# Create a distribution configuration file
cat > distribution-config.json << EOF
{
    "CallerReference": "cli-example-$(date +%s)",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-amzn-s3-demo-abcd1234",
                "DomainName": "amzn-s3-demo-abcd1234.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                },
                "OriginAccessControlId": "$OAC_ID"
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-amzn-s3-demo-abcd1234",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
        "DefaultTTL": 86400,
        "MinTTL": 0,
        "MaxTTL": 31536000,
        "Compress": true,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        }
    },
    "Comment": "CloudFront distribution for S3 bucket",
    "Enabled": true
}
EOF

# Create the CloudFront distribution
aws cloudfront create-distribution --distribution-config file://distribution-config.json
```

The output will be a large JSON object containing details about your new distribution. The important parts to note are the `Id` and `DomainName`:

```json
{
    "Distribution": {
        "Id": "EABCD1234XMPL",
        "ARN": "arn:aws:cloudfront::123456789012:distribution/EABCD1234XMPL",
        "Status": "InProgress",
        "LastModifiedTime": "2025-01-13T12:00:00.000Z",
        "DomainName": "d1abcd1234xmpl.cloudfront.net",
        ...
    }
}
```

Save the distribution ID and domain name for later use:

```bash
DISTRIBUTION_ID="EABCD1234XMPL"
DOMAIN_NAME="d1abcd1234xmpl.cloudfront.net"
```

**Update the S3 bucket policy**

Now, create and apply a bucket policy that allows CloudFront to access your S3 bucket. Replace the example bucket name with your bucket name.

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Create the bucket policy
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::amzn-s3-demo-abcd1234/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::$ACCOUNT_ID:distribution/$DISTRIBUTION_ID"
                }
            }
        }
    ]
}
EOF

# Apply the bucket policy
aws s3api put-bucket-policy \
    --bucket amzn-s3-demo-abcd1234 \
    --policy file://bucket-policy.json
```

This policy allows only your CloudFront distribution to access objects in your S3 bucket, preventing direct access from the internet.

**Wait for the distribution to deploy**

CloudFront distributions take some time to deploy. You can check the status with:

```bash
# Check the deployment status
aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status'
```

Wait until the status changes from "InProgress" to "Deployed" (this may take 5-10 minutes):

```bash
# Wait for the distribution to be deployed
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID
```

## Access your content through CloudFront

Once your distribution is deployed, you can access your content using the CloudFront domain name.

**Access your content**

To access your content, combine your CloudFront domain name with the path to your content. Replace the example domain name with your own.

```
https://d1abcd1234xmpl.cloudfront.net/index.html
```

Open this URL in your web browser to see your "Hello world!" webpage.

When you upload more content to your S3 bucket, you can access it through CloudFront by combining the CloudFront domain name with the path to the object in the S3 bucket. For example, if you upload a new file named `new-page.html` to the root of your S3 bucket, the URL would be:

```
https://d1abcd1234xmpl.cloudfront.net/new-page.html
```

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Disable and delete the CloudFront distribution**

First, disable the CloudFront distribution:

```bash
# Get the current configuration and ETag
ETAG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --query 'ETag' --output text)

# Create a modified configuration with Enabled=false
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID | \
jq '.DistributionConfig.Enabled = false' > temp_disabled_config.json

# Update the distribution to disable it
aws cloudfront update-distribution \
    --id $DISTRIBUTION_ID \
    --distribution-config file://<(jq '.DistributionConfig' temp_disabled_config.json) \
    --if-match $ETAG
```

Wait for the distribution to be disabled (this may take 15-20 minutes):

```bash
# Wait for the distribution to be disabled
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID
```

Then delete the distribution:

```bash
# Get the current ETag
ETAG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --query 'ETag' --output text)

# Delete the distribution
aws cloudfront delete-distribution --id $DISTRIBUTION_ID --if-match $ETAG
```

**Delete the origin access control**

Delete the origin access control:

```bash
# Get the OAC ETag
OAC_ETAG=$(aws cloudfront get-origin-access-control --id $OAC_ID --query 'ETag' --output text)

# Delete the OAC
aws cloudfront delete-origin-access-control --id $OAC_ID --if-match $OAC_ETAG
```

**Delete the S3 bucket and its contents**

Finally, delete the S3 bucket and its contents. Replace the example bucket name with your own.

```bash
# Delete the bucket contents
aws s3 rm s3://amzn-s3-demo-abcd1234 --recursive

# Delete the bucket
aws s3 rb s3://amzn-s3-demo-abcd1234
```

**Clean up local files**

Clean up the local files created during this tutorial:

```bash
# Clean up local files
rm -f distribution-config.json bucket-policy.json temp_disabled_config.json
rm -rf ~/cloudfront-demo
```

## Going to production

This tutorial demonstrates a basic CloudFront setup for educational purposes. For production environments, consider the following additional best practices:

### Security Considerations

1. **Enable Access Logging**
   - Configure CloudFront and S3 access logging to track requests and detect unauthorized access attempts
   - See [CloudFront logging](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/logging-and-monitoring.html)

2. **Configure AWS WAF**
   - Add AWS WAF to protect against common web exploits
   - See [Using AWS WAF with CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-awswaf.html)

3. **Enable S3 Block Public Access**
   - Ensure S3 Block Public Access settings are enabled at the bucket level
   - See [Blocking public access to S3 storage](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)

### Architecture Best Practices

1. **High Availability**
   - Configure origin failover with multiple origins
   - See [Creating an origin failover policy](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/high_availability_origin_failover.html)

2. **Performance Optimization**
   - Configure multiple cache behaviors for different content types
   - See [Cache behavior settings](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesCacheBehavior)

3. **Monitoring and Alerting**
   - Set up CloudWatch alarms for distribution metrics
   - See [Monitoring CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/monitoring-using-cloudwatch.html)

For comprehensive guidance on building production-ready architectures, refer to the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).

## Next steps

Now that you've learned how to create a basic CloudFront distribution with the AWS CLI, you can explore more advanced features:

1. [Use custom URLs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html) to serve content from your own domain name instead of the CloudFront domain.
2. [Serve private content with signed URLs and signed cookies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html) to restrict access to your content.
3. [Configure cache behaviors](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesCacheBehavior) to optimize caching for different types of content.
4. [Set up CloudFront with an S3 website endpoint](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html#concept_S3Origin_website) for hosting a complete website.
5. [Configure logging and monitoring](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/logging-and-monitoring.html) to track viewer requests and distribution performance.

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.