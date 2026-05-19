import boto3
import time

region = 'us-east-1'
import os, sys
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN') or (sys.argv[1] if len(sys.argv) > 1 else None)
if not ROLE_ARN:
    print('Usage: python3 script.py <role-arn>')
    print('Or set TUTORIAL_ROLE_ARN environment variable')
    print('Create the role with: aws cloudformation deploy --template-file prereqs.yaml --stack-name tutorial-prereqs --capabilities CAPABILITY_NAMED_IAM')
    sys.exit(1)
suffix = str(int(time.time()))[-6:]
stream_name = f'test-stream-{suffix}'

client = boto3.client('firehose', region_name=region)

try:
    print("Creating delivery stream...")
    client.create_delivery_stream(
        DeliveryStreamName=stream_name,
        DeliveryStreamType='DirectPut',
        ExtendedS3DestinationConfiguration={
            'RoleARN': ROLE_ARN,
            'BucketARN': 'arn:aws:s3:::example-bucket',
            'BufferingHints': {
                'SizeInMBs': 5,
                'IntervalInSeconds': 300
            }
        },
        Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'firehose-gs'}]
    )

    print("Waiting for stream to be created...")
    waiter = client.get_waiter('delivery_stream_active')
    waiter.wait(DeliveryStreamName=stream_name)

    print("Describing delivery stream...")
    client.describe_delivery_stream(DeliveryStreamName=stream_name)

    print("Listing delivery streams...")
    client.list_delivery_streams()

    print("Listing tags for delivery stream...")
    client.list_tags_for_delivery_stream(DeliveryStreamName=stream_name)

    print("Putting record...")
    client.put_record(
        DeliveryStreamName=stream_name,
        Record={'Data': 'test data'}
    )

    print("Putting record batch...")
    client.put_record_batch(
        DeliveryStreamName=stream_name,
        Records=[{'Data': 'test data 1'}, {'Data': 'test data 2'}]
    )

    print("Starting delivery stream encryption...")
    client.start_delivery_stream_encryption(DeliveryStreamName=stream_name)

    print("Stopping delivery stream encryption...")
    client.stop_delivery_stream_encryption(DeliveryStreamName=stream_name)

    print("Untagging delivery stream...")
    client.untag_delivery_stream(
        DeliveryStreamName=stream_name,
        TagKeys=['Name', 'project', 'tutorial']
    )

    print("Deleting delivery stream...")
    client.delete_delivery_stream(DeliveryStreamName=stream_name)

    print("PASS")
except Exception as e:
    print(f"Error: {e}")