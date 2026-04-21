# Ec2 Snapshots

An AWS CLI tutorial that demonstrates Ec2 operations.

## Running

```bash
bash ec2-snapshots.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash ec2-snapshots.sh
```

## What it does

1. Creating a volume
2. Creating a snapshot
3. Describing snapshot
4. Copying snapshot (same region)
5. Listing snapshots

## Resources created

- Snapshot
- Volume

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

