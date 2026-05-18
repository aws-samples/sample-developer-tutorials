import boto3
import time
import random
import string
import botocore

client = boto3.client('elementalinference', region_name='us-east-1')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
feed_name = f'example-feed-{suffix}'

# Create Feed
try:
    if 'Tags' in client.create_feed.__func__.__annotations__:
        response = client.create_feed(
            name=feed_name,
            outputs=[{
                'name': 'output-name',
                'outputConfig': {
                    'cropping': {}
                },
               'status': 'ENABLED'
            }],
            Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'elementalinference-gs'}]
        )
    else:
        response = client.create_feed(
            name=feed_name,
            outputs=[{
                'name': 'output-name',
                'outputConfig': {
                    'cropping': {}
                },
              'status': 'ENABLED'
            }]
        )
        if 'Arn' in response:
            client.tag_resource(ResourceARN=response['Arn'], Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'elementalinference-gs'}])

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