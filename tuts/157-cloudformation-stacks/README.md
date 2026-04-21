# Cloudformation Stacks

An AWS CLI tutorial that demonstrates Cloudformation operations.

## Running

```bash
bash cloudformation-stacks.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash cloudformation-stacks.sh
```

## What it does

1. Creating a CloudFormation template
2. Creating stack: $STACK_NAME
3. Stack outputs
4. Listing stack resources
5. Stack events

## Resources created

- Stack

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI cloudformation reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/index.html)

