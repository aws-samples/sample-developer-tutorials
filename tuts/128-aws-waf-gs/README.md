# Aws Waf Gs

An AWS CLI tutorial that demonstrates Wafv2 operations.

## Running

```bash
bash aws-waf-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-waf-gs.sh
```

## What it does

1. Creating web ACL: $ACL_NAME
2. Describing web ACL
3. Listing available managed rule groups
4. Listing web ACLs

## Resources created

- Web Acl

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI wafv2 reference](https://docs.aws.amazon.com/cli/latest/reference/wafv2/index.html)

