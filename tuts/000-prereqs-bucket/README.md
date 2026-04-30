# Shared tutorial S3 bucket

Creates a shared S3 bucket used by tutorials that need object storage. Tutorials check for this stack automatically — if it exists, they use the shared bucket instead of creating their own.

## Deploy

```bash
bash tuts/000-prereqs-bucket/prereqs-bucket.sh
```

## Clean up

```bash
bash tuts/000-prereqs-bucket/cleanup-prereqs-bucket.sh
```

## Resources created

- S3 bucket (named `tutorial-bucket-<account>-<region>`)
- CloudFormation stack `tutorial-prereqs-bucket` (exports the bucket name)

## Used by

Tutorials that create S3 buckets check for this stack first:
003, 005, 028, 037, 053, 061, 074
