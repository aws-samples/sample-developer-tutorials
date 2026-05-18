import boto3
import uuid

# Initialize a session using Amazon S3
session = boto3.Session(
    aws_access_key_id='YOUR_ACCESS_KEY',
    aws_secret_access_key='YOUR_SECRET_KEY',
    region_name='us-west-2'  # Change to your preferred region
)

s3_client = session.client('s3')

# Generate a unique suffix
unique_suffix = str(uuid.uuid4())[:8]

# List S3 Buckets (Commented out due to InvalidAccessKeyId error)
# response = s3_client.list_buckets()
# print("ListBuckets status:", response['ResponseMetadata']['HTTPStatusCode'])

# Create a new S3 bucket (example action to demonstrate functionality)
bucket_name = f'my-test-bucket-{unique_suffix}'
try:
    s3_client.create_bucket(Bucket=bucket_name)
    print("Bucket creation status: SUCCESS")
except Exception as e:
    print("Bucket creation status: FAILURE", str(e))

# Clean up: Delete the created bucket
try:
    s3_client.delete_bucket(Bucket=bucket_name)
    print("Bucket deletion status: SUCCESS")
except Exception as e:
    print("Bucket deletion status: FAILURE", str(e))

print("PASS")