# S3 Encryption

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating bucket"; B="enc-tut-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)-$(aws sts get-caller-identity --query Account --output text)"; aws s3api create-bucket --bucket "$B" > /dev/null; echo "Step 2: Enabling SSE-S3"; aws s3api put-bucket-encryption --bucket "$B" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'; echo "Step 3: Checking encryption"; aws s3api get-bucket-encryption --bucket "$B" --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault" --output table; echo "Step 4: Uploading encrypted object"; echo test > /tmp/enc.txt; aws s3 cp /tmp/enc.txt "s3://$B/test.txt" --quiet; aws s3api head-object --bucket "$B" --key test.txt --query "{Encryption:ServerSideEncryption}" --output table; echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && { aws s3 rm "s3://$B" --recursive --quiet; aws s3 rb "s3://$B

The script handles this step automatically. See `s3-encryption.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

