import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('cloudfront-keyvaluestore', region_name='us-east-1')

try:
    print("Listing keys...")
    response = client.list_keys()
    print(response)

    print("Describing key value store...")
    response = client.describe_key_value_store()
    print(response)

    print("Putting a key...")
    key_name = f'test-key-{suffix}'
    client.put_key(Key=key_name, Value='test-value', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'cloudfront-keyvaluestore-gs'}])

    print("Getting the key...")
    response = client.get_key(Key=key_name)
    print(response)

    print("PASS")

finally:
    print("Cleaning up created resources...")
    client.delete_key(Key=key_name)