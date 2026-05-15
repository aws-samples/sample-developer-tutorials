# MediaPackage V2 Channel Group Creation Tutorial

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate permissions.
- `mediapackagev2` AWS CLI commands available.

## Steps

**Step 1: Creating Channel Group**

```sh
$ aws mediapackagev2 create-channel-group \
    --channel-group-name "test-channel-group-xmpl" \
    --client-token "xmpl" \
    --description "Test Channel Group" \
    --tags '{"project": "doc-smith", "tutorial": "mediapackagev2-gs", "Environment": "Test"}'
```

This command creates a new channel group with a unique name, a client token for idempotency, a description, and specified tags.

**Step 2: Verifying Channel Group Creation**

```sh
$ aws mediapackagev2 get-channel-group \
    --channel-group-name "test-channel-group-xmpl"
```

This command verifies the creation of the channel group by retrieving its details.

**Step 3: Listing Channel Groups**

```sh
$ aws mediapackagev2 list-channel-groups \
    --max-results 10
```

This command lists up to 10 channel groups, allowing you to see the newly created channel group among others.

**Step 4: Deleting Channel Group**

```sh
$ aws mediapackagev2 delete-channel-group \
    --channel-group-name "test-channel-group-xmpl"
```

This command deletes the created channel group to clean up resources.

## Clean up

The script automatically cleans up created resources upon completion or interruption. It deletes the channel group and removes temporary files.

## Next steps

- Explore additional MediaPackage V2 features such as creating channels and origins.
- Review the [MediaPackage V2 documentation](https://docs.aws.amazon.com/mediapackage/latest/ug/what-is.html) for more advanced configurations and use cases.