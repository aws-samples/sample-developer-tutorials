# Verified Permissions Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage Verified Permissions resources.

## Steps

### 1. Create a Policy Store

**Create a Policy Store**

```bash
$ aws verifiedpermissions create-policy-store --validation-settings '{"mode":"OFF"}' --query 'policyStoreId' --output text
```

This command creates a new policy store with validation settings turned off. The output is the policy store ID, which is stored in the `STORE_ID` variable.

**Tag the Policy Store**

```bash
$ aws sts get-caller-identity --query 'Account' --output text
$ aws verifiedpermissions tag-resource --resource-arn "arn:aws:verifiedpermissions::${ACCOUNT_ID}:policy-store/${STORE_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=verifiedpermissions-gs
```

These commands retrieve your AWS account ID and tag the newly created policy store with `project:doc-smith` and `tutorial:verifiedpermissions-gs`.

### 2. Get Policy Store Details

**Get Policy Store**

```bash
$ aws verifiedpermissions get-policy-store --policy-store-id "$STORE_ID" --query 'createdDate' --output text
```

This command retrieves the creation date of the policy store.

### 3. List Policy Stores

**List Policy Stores**

```bash
$ aws verifiedpermissions list-policy-stores --query 'policyStores[].policyStoreId' --output text
```

This command lists all policy stores in your account.

## Clean up

To clean up the resources created during this tutorial, the script automatically handles the deletion of the policy store and removal of temporary files. No manual intervention is required.

## Next steps

Explore more about AWS Verified Permissions by checking the [official documentation](https://docs.aws.amazon.com/verifiedpermissions/).
