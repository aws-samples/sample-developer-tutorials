# Connect Cases Domain Creation and Deletion Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete Connect Cases domains.

## Steps

**Step 1: Creating domain**

```bash
$ aws connectcases create-domain --name "test-domain-xmpl" --query 'domainId' --output text
```

This command creates a new Connect Cases domain with a unique name. The domain ID is captured and used in subsequent steps.

**Step 2: Tagging the domain**

```bash
$ aws connectcases tag-resource --arn "arn:aws:connectcases:region:123456789012:domain/xmpl" --tags '{"project":"doc-smith","tutorial":"connectcases-gs"}'
```

This command tags the created domain with specific metadata for easier identification and management.

**Step 3: Deleting domain**

```bash
$ aws connectcases delete-domain --domainId "xmpl"
```

This command deletes the created domain. A short wait is included to ensure the deletion propagates correctly.

## Clean up

The script automatically cleans up all created resources by deleting the domain and removing temporary files.

## Next steps

- Explore additional Connect Cases features and configurations.
- Review AWS documentation for best practices in managing Connect Cases domains.