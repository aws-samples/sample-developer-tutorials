# Iam Access Analyzer

An AWS CLI tutorial that demonstrates Accessanalyzer operations.

## Running

```bash
bash iam-access-analyzer.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash iam-access-analyzer.sh
```

## What it does

1. Creating analyzer: $ANALYZER
2. Listing findings
3. Getting analyzer details
4. Listing analyzers

## Resources created

- Analyzer

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI accessanalyzer reference](https://docs.aws.amazon.com/cli/latest/reference/accessanalyzer/index.html)

