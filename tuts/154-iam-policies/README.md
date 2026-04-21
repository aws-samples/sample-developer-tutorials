# Iam Policies

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash iam-policies.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash iam-policies.sh
```

## What it does

1. Creating a custom policy
2. Getting policy details
3. Getting policy version (the actual document)
4. Creating a role and attaching the policy
5. Listing attached policies
6. Simulating policy

## Resources created

- Policy
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

