# S3: Store and retrieve objects

Create an S3 bucket, upload and download objects, enable versioning, configure encryption, and clean up.

## Source

https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html

## Use case

- ID: s3/getting-started
- Phase: create
- Complexity: beginner
- Core actions: s3api:CreateBucket, s3api:PutObject, s3api:GetObject, s3api:CopyObject

## What it does

1. Creates an S3 bucket with a random name
2. Uploads a sample text file
3. Downloads and displays the file
4. Copies the object to a folder prefix
5. Enables versioning and uploads a second version
6. Configures SSE-S3 encryption and blocks all public access
7. Tags the bucket
8. Lists objects and object versions
9. Cleans up all objects and the bucket

## Running

```bash
bash s3-gettingstarted.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-gettingstarted.sh
```

## Resources created

- S3 bucket (with versioning, encryption, public access block, tags)
- Objects (sample file, copy, second version)

## Estimated time

- Run: ~15 seconds
- Cleanup: ~5 seconds

## Cost

Free tier eligible. Minimal charges for a few small objects.
