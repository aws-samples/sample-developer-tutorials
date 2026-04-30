# Aws Cleanrooms Gs

An AWS CLI tutorial that demonstrates Cleanrooms operations.

## Running

```bash
bash aws-cleanrooms-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-cleanrooms-gs.sh
```

## What it does

1. Creating collaboration: $COLLAB_NAME
2. Creating membership
3. Describing collaboration
4. Listing collaborations

## Resources created

- Collaboration
- Membership

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI cleanrooms reference](https://docs.aws.amazon.com/cli/latest/reference/cleanrooms/index.html)

