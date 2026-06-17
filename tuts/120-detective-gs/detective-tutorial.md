# Detective Graph Creation Tutorial

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate permissions.

## Steps

**Step 1: Creating Detective graph**

```bash
$ aws detective create-graph --query 'GraphArn' --output text
```

This command creates a new Detective graph and returns its ARN. The graph is tagged with `project=doc-smith` and `tutorial=detective-gs`.

**Step 2: Listing graphs**

```bash
$ aws detective list-graphs --query 'GraphList[0].Arn' --output text
```

This command lists the ARNs of existing Detective graphs. The output is obfuscated as `123456789012`.

**Step 3: Deleting graph**

```bash
$ aws detective delete-graph --graph-arn "$GRAPH_ARN" || true
```

This command deletes the created Detective graph. The `|| true` ensures the script continues even if the deletion fails.

## Clean up

All created resources are automatically cleaned up at the end of the script. The temporary directory and log file are also removed.

## Next steps

Explore more AWS Detective features and integrate them into your security operations.
