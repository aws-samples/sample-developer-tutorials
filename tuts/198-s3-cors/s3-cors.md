# S3 Cors

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating bucket"; aws s3api create-bucket --bucket "$B

The script handles this step automatically. See `s3-cors.sh` for the exact CLI commands.

## Step 2: Setting CORS"; aws s3api put-bucket-cors --bucket "$B" --cors-configuration '{"CORSRules":[{"AllowedOrigins":["https://example.com"],"AllowedMethods":["GET","PUT"],"AllowedHeaders":["*"],"MaxAgeSeconds

The script handles this step automatically. See `s3-cors.sh` for the exact CLI commands.

## Step 3: Getting CORS"; aws s3api get-bucket-cors --bucket "$B

The script handles this step automatically. See `s3-cors.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

