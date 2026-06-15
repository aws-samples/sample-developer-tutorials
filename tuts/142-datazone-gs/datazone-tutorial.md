# Getting started with Amazon DataZone

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- AWS CLI installed and configured with appropriate IAM permissions.
- If necessary, create a CloudFormation stack to provision required IAM roles.

## Step 1: Create Account Pool

**Create an account pool**

The following script creates an account pool in Amazon DataZone. An account pool is a collection of AWS accounts that can share data products.

```bash
$ aws datazone create-account-pool --tags '{"Name":"TutorialPool","Purpose":"Demo"}' --query 'id' --output text
```

**Expected result**

The command returns the ID of the created account pool. Example output:

```
abc123
```

## Step 2: Create Asset Type

**Create an asset type**

The following script creates an asset type in Amazon DataZone. An asset type defines the schema and metadata for assets.

```bash
$ aws datazone create-asset-type --name "TutorialAssetType$(head -c 8 /dev/urandom | base64 | tr -dc a-z0-9)" --description "Asset type for tutorial" --tags '{"Name":"TutorialAssetType","Purpose":"Demo"}' --query 'id' --output text
```

**Expected result**

The command returns the ID of the created asset type. Example output:

```
def456
```

## Step 3: Create Asset

**Create an asset**

The following script creates an asset in Amazon DataZone. An asset represents a specific data entity within an asset type.

```bash
$ aws datazone create-asset --name "TutorialAsset$(head -c 8 /dev/urandom | base64 | tr -dc a-z0-9)" --asset-type-id def456 --tags '{"Name":"TutorialAsset","Purpose":"Demo"}' --query 'id' --output text
```

**Expected result**

The command returns the ID of the created asset. Example output:

```
ghi789
```

## Step 4: Create Asset Filter

**Create an asset filter**

The following script creates an asset filter in Amazon DataZone. An asset filter defines criteria for filtering assets based on their metadata.

```bash
$ aws datazone create-asset-filter --name "TutorialFilter$(head -c 8 /dev/urandom | base64 | tr -dc a-z0-9)" --asset-type-id def456 --tags '{"Name":"TutorialFilter","Purpose":"Demo"}' --query 'id' --output text
```

**Expected result**

The command returns the ID of the created asset filter. Example output:

```
jkl012
```

## Clean up

To clean up the resources created during this tutorial, run the following script. It deletes the account pool, asset type, asset, and asset filter.

```bash
$ for resource in "${CREATED_RESOURCES[@]}"; do
    case $resource in
      "account-pool:"*)
        aws datazone delete-account-pool --identifier ${resource#*:} || true
        ;;
      "asset-type:"*)
        aws datazone delete-asset-type --identifier ${resource#*:} || true
        ;;
      "asset:"*)
        aws datazone delete-asset --identifier ${resource#*:} || true
        ;;
      "asset-filter:"*)
        aws datazone delete-asset-filter --identifier ${resource#*:} || true
        ;;
    esac
  done
```

## Next steps

- Explore [Amazon DataZone documentation](https://docs.aws.amazon.com/datazone/) for more details.
- Learn how to [share data products](https://docs.aws.amazon.com/datazone/latest/userguide/sharing-data-products.html) across accounts.
- Discover [best practices](https://docs.aws.amazon.com/datazone/latest/userguide/best-practices.html) for using Amazon DataZone.
