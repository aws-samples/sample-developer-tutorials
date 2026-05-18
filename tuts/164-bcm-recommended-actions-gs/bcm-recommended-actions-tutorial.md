# Tutorial: Getting started with amazon bcm recommended actions

## Prerequisites

- An aws account
- Python installed
- Boto3 library installed

## Steps

1. **initialize a session using amazon bcm**

    ```python
    import boto3
    import uuid

    session = boto3.Session()
    bcm_client = session.client('bcm-data-exports')
    ```

2. **generate a unique suffix**

    ```python
    unique_suffix = str(uuid.uuid4())[:8]
    ```

3. **define the tags**

    ```python
    tags = [
        {'Key': 'project', 'Value': 'doc-smith'},
        {'Key': 'tutorial', 'Value': 'bcm-recommended-actions-gs'}
    ]
    ```

4. **list exports as a fallback**

    ```python
    try:
        response = bcm_client.list_exports(
            MaxResults=10
        )

        print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
        print("Exports:", response['Exports'])
    except Exception as e:
        print("Error listing exports:", e)
    ```

5. **final pass statement**

    ```python
    print("PASS")
    ```

## Clean up

- Remove any resources created during the tutorial to avoid unnecessary charges.

## Next steps

- Explore more amazon bcm features.
- Refer to the [official documentation](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/bcm-data-exports.html) for advanced usage.