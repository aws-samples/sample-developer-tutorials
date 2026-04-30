# Ec2 Security Groups

An AWS CLI tutorial that demonstrates Ec2 operations.

## Running

```bash
bash ec2-security-groups.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash ec2-security-groups.sh
```

## What it does

1. Creating security group: $SG_NAME
2. Adding inbound rules
3. Describing rules
4. Adding a tag
5. Listing security groups

## Resources created

- Security Group
- Tags

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

