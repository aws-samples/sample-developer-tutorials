# Resource Groups Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete resource groups.

## Steps

### 1. Create a Resource Group

**Command:**

```bash
$ aws resource-groups create-group \
    --name "group-abcdefg" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=resource-groups-gs \
    --resource-query '{"Type":"TAG_FILTERS_1_0","Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"project\",\"Values\":[\"doc-smith\"]}]}"}' \
    --generate-cli-skeleton > "/tmp/tmp.abcdefg/script.log"
```

This command creates a resource group named `group-abcdefg` with specific tags and a resource query. The output is saved to a log file.

### 2. List Resource Groups

**Command:**

```bash
$ aws resource-groups list-groups \
    --generate-cli-skeleton >> "/tmp/tmp.abcdefg/script.log"
```

This command lists all resource groups and appends the output to the log file.

### 3. Delete the Resource Group

**Command:**

```bash
$ aws resource-groups delete-group \
    --group-name "group-abcdefg" || true
```

This command deletes the created resource group. The `|| true` ensures the script continues even if the deletion fails.

## Clean up

The script automatically cleans up created resources by deleting the resource group and removing temporary files.

## Next steps

- Explore more complex resource group configurations.
- Integrate resource groups with other AWS services for better resource management.
