# CloudTrail: Enable logging and look up events

Create a CloudTrail trail that logs API activity to an S3 bucket, look up recent events, and clean up.

## Source

https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-tutorial.html

## Use case

- ID: cloudtrail/getting-started
- Phase: create
- Complexity: beginner
- Core actions: cloudtrail:CreateTrail, cloudtrail:StartLogging, cloudtrail:LookupEvents

## What it does

1. Creates an S3 bucket for trail logs
2. Sets the bucket policy to allow CloudTrail writes
3. Creates a trail pointing to the bucket
4. Starts logging
5. Looks up recent API events
6. Describes the trail configuration

## Running

```bash
bash aws-cloudtrail-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-cloudtrail-gs.sh
```

## Resources created

- CloudTrail trail
- S3 bucket (with CloudTrail bucket policy)

## Estimated time

- Run: ~10 seconds

## Cost

S3 storage only. CloudTrail delivers management event logs to S3 at no charge for the first trail. S3 storage costs apply for the log files.

## Related docs

- [Getting started with CloudTrail tutorials](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-tutorial.html)
- [Creating a trail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-and-update-a-trail.html)
- [Amazon S3 bucket policy for CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html)
- [Looking up events with LookupEvents](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-cli.html)
- [CloudTrail pricing](https://aws.amazon.com/cloudtrail/pricing/)
