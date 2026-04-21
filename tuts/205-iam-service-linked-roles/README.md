# Iam Service Linked Roles

A read-only script that queries Iam resources and displays information.

## Running

```bash
bash iam-service-linked-roles.sh
```

## What it does

1. Listing service-linked roles
2. Counting roles by type"; echo "  Service-linked: $(aws iam list-roles --query 'Roles[?starts_with(Path, `/aws-service-role/`)] | length(@)' --output text)

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

