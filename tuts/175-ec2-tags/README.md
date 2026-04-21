# Ec2 Tags

An AWS CLI tutorial that demonstrates Ec2 operations.

## Running

```bash
bash ec2-tags.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash ec2-tags.sh
```

## What it does

1. Adding tags
2. Describing tags
3. Finding resources by tag
4. Removing a tag

## Resources created

- Security Group
- Tags

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

