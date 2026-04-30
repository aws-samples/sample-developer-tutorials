# Iam List Users

A read-only script that queries Iam resources and displays information.

## Running

```bash
bash iam-list-users.sh
```

## What it does

1. Listing IAM users
2. User count"; echo "  Total: $(aws iam list-users --query 'Users | length(@)' --output text) users

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

