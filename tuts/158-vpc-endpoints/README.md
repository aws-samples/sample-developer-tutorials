# Vpc Endpoints

An AWS CLI tutorial that demonstrates Ec2 operations.

## Running

```bash
bash vpc-endpoints.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash vpc-endpoints.sh
```

## What it does

1. Listing available VPC endpoint services
2. Creating a gateway endpoint (S3)
3. Describing endpoint
4. Listing endpoints

## Resources created

- Vpc Endpoint

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

