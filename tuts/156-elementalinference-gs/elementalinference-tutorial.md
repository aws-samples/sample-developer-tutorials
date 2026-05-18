# Elementalinference Feed Management Tutorial

## Prerequisites

- Aws account
- Boto3 python library installed
- Aws credentials configured

## Steps

**1. Install boto3**

```markdown
$ pip install boto3
```

**2. Create a feed**

```python
import boto3
import time
import random
import string

client = boto3.client('elementalinference', region_name='us-east-1')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
feed_name = f'example-feed-{suffix}'

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
```

**3. Verify feed creation**

```python
    time.sleep(5)  # Wait for the feed to be created
    response = client.get_feed(id=feed_id)
    print(f"Feed status: {response['status']}")
```

**4. List feeds**

```python
    response = client.list_feeds()
    print(f"Listed feeds: {response['feeds']}")
```

## Clean up

**1. Delete feed**

```python
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
```

## Next steps

- Explore other elementalinference operations
- Review aws elementalinference documentation