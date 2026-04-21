# Iam Groups

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash iam-groups.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash iam-groups.sh
```

## What it does

1. Creating group: $G"; aws iam create-group --group-name "$G
2. Attaching policy"; aws iam attach-group-policy --group-name "$G
3. Describing group"; aws iam get-group --group-name "$G
4. Listing attached policies"; aws iam list-attached-group-policies --group-name "$G

## Resources created

- Group

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

