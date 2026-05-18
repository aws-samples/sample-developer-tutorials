import boto3
import uuid

# Initialize a session using Amazon S3 (SimpleDB is deprecated)
session = boto3.Session(
    aws_access_key_id='YOUR_ACCESS_KEY',
    aws_secret_access_key='YOUR_SECRET_KEY',
    region_name='us-west-2'
)

# Create a client for S3
s3 = session.client('s3')

# Generate a unique suffix for bucket name
unique_suffix = str(uuid.uuid4())[:8]

# Define bucket name with unique suffix
bucket_name = f'example-bucket-{unique_suffix}'

try:
    # Create Bucket
    s3.create_bucket(Bucket=bucket_name)
    print("CreateBucket status:", 200)

    # List Buckets
    response = s3.list_buckets()
    print("ListBuckets status:", 200)

    # Delete Bucket
    s3.delete_bucket(Bucket=bucket_name)
    print("DeleteBucket status:", 200)
except Exception as e:
    print("Error:", e)

print("PASS")