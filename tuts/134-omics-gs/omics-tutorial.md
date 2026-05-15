# Omics Sequence Store Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete sequence stores in AWS Omics.

## Steps

### Step 1: Creating Sequence Store

**Command:**

```sh
$ aws omics create-sequence-store \
    --tags '{"project": "doc-smith", "tutorial": "omics-gs"}' \
    --name "test-sequence-store-xmpl" \
    --description "Test sequence store for demonstration" \
    --client-token "xmpl" \
    --query 'id' \
    --output text
```

**Output:**

```sh
Sequence store created with ID: 123456789012
```

### Step 2: Verifying Sequence Store Creation

**Command:**

```sh
$ aws omics get-sequence-store \
    --id "123456789012" \
    --query 'name' \
    --output text
```

**Output:**

```sh
Retrieved sequence store: test-sequence-store-xmpl
```

### Step 3: Listing Sequence Stores

**Command:**

```sh
$ aws omics list-sequence-stores \
    --max-results 10
```

**Output:**

```sh
List of sequence stores: {"sequenceStores": [{"id": "123456789012", "name": "test-sequence-store-xmpl", "description": "Test sequence store for demonstration", "creationTime": "2023-10-02T12:00:00Z"}]}
```

### Step 4: Deleting Sequence Store

**Command:**

```sh
$ aws omics delete-sequence-store \
    --id "123456789012"
```

**Output:**

```sh
Sequence store deleted
```

## Clean Up

All created resources are automatically cleaned up at the end of the script.

## Next Steps

- Explore more AWS Omics features.
- Refer to the [AWS Omics documentation](https://docs.aws.amazon.com/omics/) for advanced use cases.