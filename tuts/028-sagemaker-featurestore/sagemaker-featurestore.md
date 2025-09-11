# Getting started with Amazon SageMaker Feature Store using the AWS CLI

This tutorial guides you through the process of using Amazon SageMaker Feature Store with the AWS Command Line Interface (AWS CLI). You'll learn how to create feature groups, ingest data, and retrieve features for machine learning workflows.

## Topics

* [Prerequisites](#prerequisites)
* [Set up IAM permissions](#set-up-iam-permissions)
* [Create a SageMaker execution role](#create-a-sagemaker-execution-role)
* [Create feature groups](#create-feature-groups)
* [Ingest data into feature groups](#ingest-data-into-feature-groups)
* [Retrieve records from feature groups](#retrieve-records-from-feature-groups)
* [Clean up resources](#clean-up-resources)
* [Going to production](#going-to-production)
* [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-adding-policies.html) to create and manage SageMaker Feature Store resources in your AWS account, including permissions to create IAM roles and policies.

**Estimated time to complete:** 30-45 minutes

**Estimated cost:** The resources created in this tutorial will cost less than $0.02 if you complete the tutorial within an hour and delete all resources afterward. Costs are primarily associated with the SageMaker Feature Store online store, which charges for storage and read/write operations. For current pricing information, see [Amazon SageMaker Feature Store pricing](https://aws.amazon.com/sagemaker/feature-store/pricing/).

Let's get started with creating and managing Amazon SageMaker Feature Store resources using the CLI.

## Set up IAM permissions

Before using SageMaker Feature Store, you need to ensure your IAM role has the necessary permissions. The role needs permissions to create and manage feature groups, as well as access to Amazon S3 for the offline store.

**Create a policy for SageMaker Feature Store access**

The following command creates a policy that grants the necessary permissions for SageMaker Feature Store operations. Replace `123456789012` with your AWS account ID.

```
aws iam create-policy \
    --policy-name SageMakerFeatureStorePolicy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sagemaker:CreateFeatureGroup",
                    "sagemaker:DescribeFeatureGroup",
                    "sagemaker:DeleteFeatureGroup",
                    "sagemaker:ListFeatureGroups",
                    "sagemaker:UpdateFeatureGroup"
                ],
                "Resource": "arn:aws:sagemaker:*:123456789012:feature-group/*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "sagemaker-featurestore-runtime:PutRecord",
                    "sagemaker-featurestore-runtime:GetRecord",
                    "sagemaker-featurestore-runtime:DeleteRecord",
                    "sagemaker-featurestore-runtime:BatchGetRecord"
                ],
                "Resource": "arn:aws:sagemaker:*:123456789012:feature-group/*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation",
                    "s3:GetBucketVersioning"                    
                ],
                "Resource": [
                    "arn:aws:s3:::amzndemo-s3-demo-bucket/*",
                    "arn:aws:s3:::amzndemo-s3-demo-bucket"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "glue:CreateTable",
                    "glue:GetTable",
                    "glue:GetPartitions",
                    "glue:CreatePartition",
                    "glue:UpdatePartition",
                    "glue:DeletePartition"
                ],
                "Resource": "*"
            }            
        ]
    }'
```

This command creates a policy that allows the necessary SageMaker Feature Store operations and S3 access. The policy is named `SageMakerFeatureStorePolicy` and follows the principle of least privilege by specifying resource ARNs.

## Create a SageMaker execution role

If you don't already have a SageMaker execution role, you can create one with the necessary permissions for this tutorial.

**Create the trust policy document**

First, create a trust policy that allows SageMaker to assume the role:

```
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "sagemaker.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
```

**Create the IAM role**

Create the SageMaker execution role using the trust policy:

```
aws iam create-role \
    --role-name YourSageMakerExecutionRole \
    --assume-role-policy-document file://trust-policy.json \
    --description "SageMaker execution role for Feature Store tutorial"
```

**Attach the policy to your role**

After creating the policy, attach it to the SageMaker execution role. Replace `YourSageMakerExecutionRole` with the name of your SageMaker execution role and `123456789012` with your AWS account ID. 

```
aws iam attach-role-policy \
    --role-name YourSageMakerExecutionRole \
    --policy-arn arn:aws:iam::123456789012:policy/SageMakerFeatureStorePolicy
```

This command attaches the policy to your role, granting it the necessary permissions.

## Create feature groups

Feature groups are the main resources in SageMaker Feature Store. They contain your machine learning features and records. In this section, you'll create two feature groups: one for customer data and one for order data.

**Set up variables**

First, set up some variables that will be used throughout the tutorial. Replace `arn:aws:iam::123456789012:role/YourSageMakerExecutionRole` with your actual SageMaker execution role ARN. These variables will be used in subsequent commands.

```
# Set variables
ROLE_ARN="arn:aws:iam::123456789012:role/YourSageMakerExecutionRole"
S3_BUCKET_NAME="amzndemo-s3-demo-bucket"
PREFIX="featurestore-tutorial"
CURRENT_TIME=$(date +%s)

# Generate unique names for feature groups
CUSTOMERS_FEATURE_GROUP_NAME="customers-feature-group-abcd1234"
ORDERS_FEATURE_GROUP_NAME="orders-feature-group-abcd1234"
```



**Create an S3 bucket for the offline store**

SageMaker Feature Store uses an S3 bucket for its offline store. Create a bucket with the following command:

```
# Create S3 bucket in your current region
REGION=$(aws configure get region)

if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$S3_BUCKET_NAME"
else
    aws s3api create-bucket \
        --bucket "$S3_BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION"
fi

# Block public access to the bucket
aws s3api put-public-access-block \
    --bucket "$S3_BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$S3_BUCKET_NAME" \
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

This creates an S3 bucket for storing feature data offline, blocks all public access to the bucket, and enables server-side encryption for security.

**Create customers feature group**

Now, create a feature group for customer data:

```
aws sagemaker create-feature-group \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME" \
    --record-identifier-feature-name "customer_id" \
    --event-time-feature-name "EventTime" \
    --feature-definitions '[
        {"FeatureName": "customer_id", "FeatureType": "Integral"},
        {"FeatureName": "name", "FeatureType": "String"},
        {"FeatureName": "age", "FeatureType": "Integral"},
        {"FeatureName": "address", "FeatureType": "String"},
        {"FeatureName": "membership_type", "FeatureType": "String"},
        {"FeatureName": "EventTime", "FeatureType": "Fractional"}
    ]' \
    --online-store-config '{"EnableOnlineStore": true}' \
    --offline-store-config '{
        "S3StorageConfig": {
            "S3Uri": "s3://'${S3_BUCKET_NAME}'/'${PREFIX}'"
        },
        "DisableGlueTableCreation": false
    }' \
    --role-arn "$ROLE_ARN" \
    --tags '[{"Key": "Project", "Value": "FeatureStoreTutorial"}, {"Key": "Environment", "Value": "Tutorial"}]'
```

This command creates a feature group named `customers-feature-group-abcd1234` with both online and offline stores enabled. The feature group includes definitions for customer attributes like ID, name, age, address, and membership type. We've also added tags to help with resource management.

**Create orders feature group**

Similarly, create a feature group for order data:

```
aws sagemaker create-feature-group \
    --feature-group-name "$ORDERS_FEATURE_GROUP_NAME" \
    --record-identifier-feature-name "customer_id" \
    --event-time-feature-name "EventTime" \
    --feature-definitions '[
        {"FeatureName": "customer_id", "FeatureType": "Integral"},
        {"FeatureName": "order_id", "FeatureType": "String"},
        {"FeatureName": "order_date", "FeatureType": "String"},
        {"FeatureName": "product", "FeatureType": "String"},
        {"FeatureName": "quantity", "FeatureType": "Integral"},
        {"FeatureName": "amount", "FeatureType": "Fractional"},
        {"FeatureName": "EventTime", "FeatureType": "Fractional"}
    ]' \
    --online-store-config '{"EnableOnlineStore": true}' \
    --offline-store-config '{
        "S3StorageConfig": {
            "S3Uri": "s3://'${S3_BUCKET_NAME}'/'${PREFIX}'"
        },
        "DisableGlueTableCreation": false
    }' \
    --role-arn "$ROLE_ARN" \
    --tags '[{"Key": "Project", "Value": "FeatureStoreTutorial"}, {"Key": "Environment", "Value": "Tutorial"}]'
```

This command creates a feature group named `orders-feature-group-abcd1234` with similar configuration but different feature definitions related to order data.

**Check feature group status**

After creating the feature groups, check their status to ensure they're ready for use:

```
# Check status of customers feature group
aws sagemaker describe-feature-group \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME" \
    --query 'FeatureGroupStatus'

# Check status of orders feature group
aws sagemaker describe-feature-group \
    --feature-group-name "$ORDERS_FEATURE_GROUP_NAME" \
    --query 'FeatureGroupStatus'
```

Wait until both feature groups show a status of "Created" before proceeding to the next step. This may take a few minutes.

## Ingest data into feature groups

Once your feature groups are created, you can ingest data into them. In this section, you'll add customer and order records to their respective feature groups.

**Ingest customer data**

Use the following commands to ingest two customer records:

```
# Ingest first customer record
aws sagemaker-featurestore-runtime put-record \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME" \
    --record '[
        {"FeatureName": "customer_id", "ValueAsString": "573291"},
        {"FeatureName": "name", "ValueAsString": "John Doe"},
        {"FeatureName": "age", "ValueAsString": "35"},
        {"FeatureName": "address", "ValueAsString": "123 Main St"},
        {"FeatureName": "membership_type", "ValueAsString": "premium"},
        {"FeatureName": "EventTime", "ValueAsString": "'${CURRENT_TIME}'"}
    ]'

# Ingest second customer record
aws sagemaker-featurestore-runtime put-record \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME" \
    --record '[
        {"FeatureName": "customer_id", "ValueAsString": "109382"},
        {"FeatureName": "name", "ValueAsString": "Jane Smith"},
        {"FeatureName": "age", "ValueAsString": "28"},
        {"FeatureName": "address", "ValueAsString": "456 Oak Ave"},
        {"FeatureName": "membership_type", "ValueAsString": "standard"},
        {"FeatureName": "EventTime", "ValueAsString": "'${CURRENT_TIME}'"}
    ]'
```

These commands add two customer records to the customers feature group. Each record includes a customer ID, name, age, address, membership type, and an event timestamp.

**Ingest order data**

Similarly, ingest two order records:

```
# Ingest first order record
aws sagemaker-featurestore-runtime put-record \
    --feature-group-name "$ORDERS_FEATURE_GROUP_NAME" \
    --record '[
        {"FeatureName": "customer_id", "ValueAsString": "573291"},
        {"FeatureName": "order_id", "ValueAsString": "ORD-001"},
        {"FeatureName": "order_date", "ValueAsString": "2023-01-15"},
        {"FeatureName": "product", "ValueAsString": "Laptop"},
        {"FeatureName": "quantity", "ValueAsString": "1"},
        {"FeatureName": "amount", "ValueAsString": "1299.99"},
        {"FeatureName": "EventTime", "ValueAsString": "'${CURRENT_TIME}'"}
    ]'

# Ingest second order record
aws sagemaker-featurestore-runtime put-record \
    --feature-group-name "$ORDERS_FEATURE_GROUP_NAME" \
    --record '[
        {"FeatureName": "customer_id", "ValueAsString": "109382"},
        {"FeatureName": "order_id", "ValueAsString": "ORD-002"},
        {"FeatureName": "order_date", "ValueAsString": "2023-01-20"},
        {"FeatureName": "product", "ValueAsString": "Smartphone"},
        {"FeatureName": "quantity", "ValueAsString": "1"},
        {"FeatureName": "amount", "ValueAsString": "899.99"},
        {"FeatureName": "EventTime", "ValueAsString": "'${CURRENT_TIME}'"}
    ]'
```

These commands add two order records to the orders feature group, each associated with one of the customers you added earlier.

## Retrieve records from feature groups

After ingesting data, you can retrieve records from your feature groups. This section demonstrates how to fetch individual and multiple records.

**Get a single record**

To retrieve a single customer record by ID:

```
aws sagemaker-featurestore-runtime get-record \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME" \
    --record-identifier-value-as-string "573291"
```

This command retrieves the customer record with ID "573291" from the customers feature group. The output will include all features for this customer:

```
{
    "Record": [
        {
            "FeatureName": "customer_id",
            "ValueAsString": "573291"
        },
        {
            "FeatureName": "name",
            "ValueAsString": "John Doe"
        },
        {
            "FeatureName": "age",
            "ValueAsString": "35"
        },
        {
            "FeatureName": "address",
            "ValueAsString": "123 Main St"
        },
        {
            "FeatureName": "membership_type",
            "ValueAsString": "premium"
        },
        {
            "FeatureName": "EventTime",
            "ValueAsString": "1673596800"
        }
    ]
}
```

**Get multiple records**

To retrieve multiple records from different feature groups in a single request:

```
aws sagemaker-featurestore-runtime batch-get-record \
    --identifiers '[
        {
            "FeatureGroupName": "'${CUSTOMERS_FEATURE_GROUP_NAME}'",
            "RecordIdentifiersValueAsString": ["573291", "109382"]
        },
        {
            "FeatureGroupName": "'${ORDERS_FEATURE_GROUP_NAME}'",
            "RecordIdentifiersValueAsString": ["573291", "109382"]
        }
    ]'
```

This command retrieves records for both customers from both feature groups. The output will include all customer and order records for the specified IDs:

```
{
    "Records": [
        {
            "FeatureGroupName": "customers-feature-group-abcd1234",
            "RecordIdentifierValueAsString": "573291",
            "Record": [
                {
                    "FeatureName": "customer_id",
                    "ValueAsString": "573291"
                },
                {
                    "FeatureName": "name",
                    "ValueAsString": "John Doe"
                },
                {
                    "FeatureName": "age",
                    "ValueAsString": "35"
                },
                {
                    "FeatureName": "address",
                    "ValueAsString": "123 Main St"
                },
                {
                    "FeatureName": "membership_type",
                    "ValueAsString": "premium"
                },
                {
                    "FeatureName": "EventTime",
                    "ValueAsString": "1673596800"
                }
            ]
        },
        {
            "FeatureGroupName": "customers-feature-group-abcd1234",
            "RecordIdentifierValueAsString": "109382",
            "Record": [
                {
                    "FeatureName": "customer_id",
                    "ValueAsString": "109382"
                },
                {
                    "FeatureName": "name",
                    "ValueAsString": "Jane Smith"
                },
                {
                    "FeatureName": "age",
                    "ValueAsString": "28"
                },
                {
                    "FeatureName": "address",
                    "ValueAsString": "456 Oak Ave"
                },
                {
                    "FeatureName": "membership_type",
                    "ValueAsString": "standard"
                },
                {
                    "FeatureName": "EventTime",
                    "ValueAsString": "1673596800"
                }
            ]
        },
        {
            "FeatureGroupName": "orders-feature-group-abcd1234",
            "RecordIdentifierValueAsString": "573291",
            "Record": [
                {
                    "FeatureName": "customer_id",
                    "ValueAsString": "573291"
                },
                {
                    "FeatureName": "order_id",
                    "ValueAsString": "ORD-001"
                },
                {
                    "FeatureName": "order_date",
                    "ValueAsString": "2023-01-15"
                },
                {
                    "FeatureName": "product",
                    "ValueAsString": "Laptop"
                },
                {
                    "FeatureName": "quantity",
                    "ValueAsString": "1"
                },
                {
                    "FeatureName": "amount",
                    "ValueAsString": "1299.99"
                },
                {
                    "FeatureName": "EventTime",
                    "ValueAsString": "1673596800"
                }
            ]
        },
        {
            "FeatureGroupName": "orders-feature-group-abcd1234",
            "RecordIdentifierValueAsString": "109382",
            "Record": [
                {
                    "FeatureName": "customer_id",
                    "ValueAsString": "109382"
                },
                {
                    "FeatureName": "order_id",
                    "ValueAsString": "ORD-002"
                },
                {
                    "FeatureName": "order_date",
                    "ValueAsString": "2023-01-20"
                },
                {
                    "FeatureName": "product",
                    "ValueAsString": "Smartphone"
                },
                {
                    "FeatureName": "quantity",
                    "ValueAsString": "1"
                },
                {
                    "FeatureName": "amount",
                    "ValueAsString": "899.99"
                },
                {
                    "FeatureName": "EventTime",
                    "ValueAsString": "1673596800"
                }
            ]
        }
    ],
    "Errors": [],
    "UnprocessedIdentifiers": []
}
```

**List feature groups**

To see all feature groups in your account:

```
aws sagemaker list-feature-groups
```

This command lists all feature groups in your account, including their names, ARNs, creation times, and status:

```
{
    "FeatureGroupSummaries": [
        {
            "FeatureGroupName": "orders-feature-group-abcd1234",
            "FeatureGroupArn": "arn:aws:sagemaker:us-east-2:123456789012:feature-group/orders-feature-group-abcd1234",
            "CreationTime": 1673596800.000,
            "FeatureGroupStatus": "Created"
        },
        {
            "FeatureGroupName": "customers-feature-group-abcd1234",
            "FeatureGroupArn": "arn:aws:sagemaker:us-east-2:123456789012:feature-group/customers-feature-group-abcd1234",
            "CreationTime": 1673596800.000,
            "FeatureGroupStatus": "Created"
        }
    ]
}
```

## Clean up resources

When you're finished with your SageMaker Feature Store resources, you should delete them to avoid incurring additional charges. This section shows you how to clean up all the resources created in this tutorial.

**Delete feature groups**

To delete the feature groups:

```
# Delete customers feature group
aws sagemaker delete-feature-group \
    --feature-group-name "$CUSTOMERS_FEATURE_GROUP_NAME"

# Delete orders feature group
aws sagemaker delete-feature-group \
    --feature-group-name "$ORDERS_FEATURE_GROUP_NAME"
```

These commands delete the feature groups you created. Note that deleting a feature group doesn't automatically delete the data in the offline store.

**Delete S3 bucket contents and bucket**

To delete the S3 bucket and its contents:

```
# Empty the S3 bucket
aws s3 rm "s3://$S3_BUCKET_NAME" --recursive

# Delete the S3 bucket
aws s3api delete-bucket --bucket "$S3_BUCKET_NAME"
```

These commands first remove all objects from the S3 bucket and then delete the bucket itself.

**Delete the IAM role and policy (optional)**

The following commands delete the SageMaker execution role that's created for this tutorial.

Note: Replace `123456789012` with your account ID.
```
# Delete the custom policy 
aws iam detach-role-policy \
    --role-name YourSageMakerExecutionRole \
    --policy-arn "arn:aws:iam::123456789012:policy/SageMakerFeatureStorePolicy"

aws iam delete-policy \
    --policy-arn "arn:aws:iam::123456789012:policy/SageMakerFeatureStorePolicy"

# Delete the IAM role
aws iam delete-role --role-name YourSageMakerExecutionRole

# Clean up the trust policy file
rm trust-policy.json
```

These commands remove all the IAM resources created during the tutorial.

## Going to production

This tutorial is designed to help you learn how to use SageMaker Feature Store with the AWS CLI. For production environments, consider the following additional best practices:

### Security considerations

1. **Fine-grained access control**: Implement more granular IAM policies to restrict access to specific feature groups.
2. **VPC endpoints**: Use [VPC endpoints](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-use-with-vpc-endpoints.html) to access Feature Store without traversing the public internet.
3. **Encryption**: Configure [KMS encryption](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-kms-key-encryption.html) for both online and offline stores.
4. **Access logging**: Enable [S3 access logging](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html) and [CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html) for audit purposes.

### Architectural considerations

1. **Data ingestion pipelines**: Implement automated data pipelines for consistent feature ingestion.
2. **Monitoring**: Set up [CloudWatch metrics](https://docs.aws.amazon.com/sagemaker/latest/dg/monitoring-cloudwatch.html) to monitor feature freshness and availability.
3. **Feature selection**: Carefully design feature groups to optimize query performance.
4. **Backup strategy**: Implement regular backups of feature data.

For more information on building production-ready solutions with AWS services, refer to:

1. [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
2. [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
3. [SageMaker Best Practices](https://docs.aws.amazon.com/sagemaker/latest/dg/best-practices.html)

## Next steps

Now that you've learned the basics of using SageMaker Feature Store with the AWS CLI, explore these additional topics:

1. [Feature Store concepts](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-concepts.html) - Learn more about the core concepts of Feature Store.
2. [Using Feature Store with the SageMaker Python SDK](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-create-feature-group.html) - Explore how to use Feature Store in your Python code.
3. [Using Feature Store in the SageMaker console](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-use-with-studio.html) - Learn how to use Feature Store through the graphical interface.
4. [Fraud detection with Feature Store](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-fraud-detection-notebook.html) - See how Feature Store can be used in a real-world fraud detection use case.
5. [Feature Store resources](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-resources.html) - Discover additional examples and resources for Feature Store.
