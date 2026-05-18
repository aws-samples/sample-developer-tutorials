# Tutorial for Getting Started with Cloudfront Keyvaluestore

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed

## Steps

1. **Set up your environment**:
   Ensure you have AWS credentials configured and Boto3 installed.
   ```bash
   pip install boto3
   ```

2. **Initialize the Cloudfront Keyvaluestore client**:
   ```python
   import boto3
   import time
   import random

   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('cloudfront-keyvaluestore', region_name='us-east-1')
   ```

3. **List existing keys**:
   ```python
   print("Listing keys...")
   response = client.list_keys()
   print(response)
   ```

4. **Describe the key value store**:
   ```python
   print("Describing key value store...")
   response = client.describe_key_value_store()
   print(response)
   ```

5. **Put a key-value pair**:
   ```python
   print("Putting a key...")
   key_name = f'test-key-{suffix}'
   client.put_key(Key=key_name, Value='test-value', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'cloudfront-keyvaluestore-gs'}])
   ```

6. **Get the key-value pair**:
   ```python
   print("Getting the key...")
   response = client.get_key(Key=key_name)
   print(response)
   ```

7. **Verify the operation**:
   ```python
   print("PASS")
   ```

## Clean up
Delete any resources created to avoid unnecessary charges.
```python
finally:
    print("Cleaning up created resources...")
    client.delete_key(Key=key_name)
```

## Next steps
Explore more features of Cloudfront Keyvaluestore by referring to the [official documentation](https://docs.aws.amazon.com/cloudfront/latest/APIReference/Welcome.html).