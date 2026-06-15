# Getting started with Amazon Omics

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and delete Amazon Omics resources
- An AWS CloudFormation stack with necessary IAM roles if required

## Step 1: Create Reference Store

**Create a reference store**

The following script creates a reference store in Amazon Omics.

```bash
$ aws omics create-reference-store --name "ref-store-abc123" --tags '[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"omics-gs"}]'
```

**Expected result**

You should see an output similar to:

```json
{
    "id": "abc123",
    "arn": "arn:aws:omics:us-east-1:123456789012:referenceStore/ref-store-abc123"
}
```

## Step 2: Create Sequence Store

**Create a sequence store**

The following script creates a sequence store in Amazon Omics.

```bash
$ aws omics create-sequence-store --name "seq-store-abc123" --tags '[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"omics-gs"}]'
```

**Expected result**

You should see an output similar to:

```json
{
    "id": "abc123",
    "arn": "arn:aws:omics:us-east-1:123456789012:sequenceStore/seq-store-abc123"
}
```

## Step 3: Create Configuration

**Create a configuration**

The following script creates a configuration in Amazon Omics.

```bash
$ aws omics create-configuration --name "config-abc123" --computeType "ON_DEMAND" --tags '[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"omics-gs"}]'
```

**Expected result**

You should see an output similar to:

```json
{
    "id": "abc123",
    "arn": "arn:aws:omics:us-east-1:123456789012:configuration/config-abc123"
}
```

## Step 4: Create Annotation Store

**Create an annotation store**

The following script creates an annotation store in Amazon Omics.

```bash
$ aws omics create-annotation-store --name "annot-store-abc123" --storeFormat "VCF" --reference "abc123" --tags '[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"omics-gs"}]'
```

**Expected result**

You should see an output similar to:

```json
{
    "id": "abc123",
    "arn": "arn:aws:omics:us-east-1:123456789012:annotationStore/annot-store-abc123"
}
```

## Clean up

The following script deletes the created resources to avoid unnecessary charges.

**Delete resources**

```bash
$ aws omics delete-annotation-store --name "annot-store-abc123"
$ aws omics delete-configuration --id "abc123"
$ aws omics delete-sequence-store --id "abc123"
$ aws omics delete-reference-store --id "abc123"
```

**Expected result**

Each command should execute without errors, indicating the resources have been successfully deleted.

## Next steps

- Explore [Amazon Omics documentation](https://docs.aws.amazon.com/omics/) for more detailed information.
- Learn how to [import data into Amazon Omics](https://docs.aws.amazon.com/omics/latest/dev/importing-data.html).
- Discover [best practices for using Amazon Omics](https://docs.aws.amazon.com/omics/latest/dev/best-practices.html).
