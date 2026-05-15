import boto3
import time
import random
import string

client = boto3.client('elementalinference', region_name='us-east-1')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
feed_name = f'example-feed-{suffix}'

# Create Feed
try:
    response = client.create_feed(
        name=feed_name,
        outputs=[{
            'name': 'output-name',
            'outputConfig': {
                'cropping': {}
            },
           'status': 'ENABLED'
        }],
        tags={'project': 'doc-smith', 'tutorial': 'elementalinference-gs'}
    )
    feed_id = response['id']
    print(f"Created feed with ID: {feed_id}")

    # Verify Feed Creation
    time.sleep(5)  # Wait for the feed to be created
    response = client.get_feed(id=feed_id)
    print(f"Feed status: {response['status']}")

    # List Feeds
    response = client.list_feeds()
    print(f"Listed feeds: {response['feeds']}")

    # Delete Feed
    client.delete_feed(id=feed_id)
    print(f"Deleted feed with ID: {feed_id}")

    print("PASS")
except botocore.exceptions.ParamValidationError as e:
    print(f"Parameter validation failed: {e}")
    # Attempt to delete the feed if it was created before the error
    try:
        client.delete_feed(id=feed_id)
        print(f"Attempted to delete feed with ID: {feed_id}")
    except Exception as delete_error:
        print(f"Failed to delete feed: {delete_error}")
except Exception as e:
    print(f"An error occurred: {e}")
    # Attempt to delete the feed if it was created before the error
    try:
        client.delete_feed(id=feed_id)
        print(f"Attempted to delete feed with ID: {feed_id}")
    except Exception as delete_error:
        print(f"Failed to delete feed: {delete_error}")