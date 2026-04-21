# S3: Getting started

Create an S3 bucket, upload objects, copy between buckets, list contents, and clean up.

## Source

https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html

## Use case

- ID: s3/getting-started
- Phase: create
- Complexity: beginner
- Core actions: s3api:CreateBucket, s3api:PutObject, s3api:GetObject, s3api:CopyObject

## What it does

1. Creates two S3 buckets (source and destination)
2. Uploads a text file to the source bucket
3. Downloads the file and verifies contents
4. Copies the file to the destination bucket
5. Lists objects in both buckets
6. Deletes all objects and both buckets

## Running

```bash
bash s3-gettingstarted.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-gettingstarted.sh
```

## Resources created

- 2 S3 buckets
- 1 text file (uploaded as S3 object)

## Estimated time

- Run: ~15 seconds
- Cleanup: ~5 seconds

## Cost

Free tier eligible. No charges expected for a few objects.

## Related docs

- [Getting started with Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html)
- [Creating a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-bucket.html)
- [Uploading objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html)
- [Copying objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/copy-object.html)

---



## CloudFormation

This tutorial includes a CloudFormation template that creates the same resources as the CLI script.

**Resources created:** S3 bucket (uses shared prereq bucket)

### Deploy with CloudFormation

```bash
./deploy.sh 003-s3-gettingstarted
```

### Run the interactive steps

Once deployed, run the interactive tutorial steps against the CloudFormation-created resources. Each command is displayed with resolved values so you can run them individually.

```bash
bash tuts/003-s3-gettingstarted/s3-gettingstarted-cfn.sh
```

### Clean up

```bash
./cleanup.sh 003-s3-gettingstarted
```
## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 (README regenerated with appendix) |
| Source script | Regenerated from source topic, 332 lines |
| Script test result | EXIT 0, 16s, 9 steps, clean teardown |
| Issues encountered | None — straightforward S3 operations |
| Iterations | v1 (original), v2 (regenerated from source topic 2026-04-12) |
