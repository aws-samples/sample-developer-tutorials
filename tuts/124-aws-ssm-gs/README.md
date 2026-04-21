# Aws Ssm Gs

An AWS CLI tutorial that demonstrates Ssm operations.

## Running

```bash
bash aws-ssm-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-ssm-gs.sh
```

## What it does

1. Creating a String parameter
2. Creating a SecureString parameter
3. Creating a StringList parameter
4. Getting parameters
5. Getting parameters by path
6. Parameter history

## Resources created

- Parameter

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ssm reference](https://docs.aws.amazon.com/cli/latest/reference/ssm/index.html)

