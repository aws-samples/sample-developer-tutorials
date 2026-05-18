# Cloudfront Key Value Store Tutorial

## Prerequisites

- An aws account.
- Aws cli configured with appropriate permissions.
- Python installed with boto3 library.

## Steps

**1. List keys**

```bash
$ python -c 'import boto3; client = boto3.client("cloudfront-keyvaluestore", region_name="us-east-1"); print(client.list_keys())'
```

**Obfuscated output:**

```json
{
    'Keys': [
        {
            'Key': '123456789012',
            'Value': 'example-value',
            'Tags': [
                {
                    'Key': 'example-tag-key',
                    'Value': 'example-tag-value'
                }
            ]
        }
    ]
}
```

**2. Describe key value store**

```bash
$ python -c 'import boto3; client = boto3.client("cloudfront-keyvaluestore", region_name="us-east-1"); print(client.describe_key_value_store())'
```

**Obfuscated output:**

```json
{
    'KeyValueStore': {
        'Name': '123456789012',
        'Arn': 'arn:aws:cloudfront::123456789012:keyvaluestore/123456789012',
        'Status': 'ACTIVE',
        'CreationTime': '2023-10-02T12:00:00Z',
        'LastModifiedTime': '2023-10-02T12:00:00Z'
    }
}
```

**3. Put a key**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("cloudfront-keyvaluestore", region_name="us-east-1"); key_name = f''test-key-{suffix}''; client.put_key(Key=key_name, Value=''test-value'', Tags=[{''Key'':''project'',''Value'':''doc-smith''},{''Key'':''tutorial'',''Value'':''cloudfront-keyvaluestore-gs''}])'
```

**4. Get the key**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("cloudfront-keyvaluestore", region_name="us-east-1"); key_name = f''test-key-{suffix}''; print(client.get_key(Key=key_name))'
```

**Obfuscated output:**

```json
{
    'Key': 'test-key-123456',
    'Value': 'test-value',
    'Tags': [
        {
            'Key': 'project',
            'Value': 'doc-smith'
        },
        {
            'Key': 'tutorial',
            'Value': 'cloudfront-keyvaluestore-gs'
        }
    ]
}
```

## Clean up

**Delete the key**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("cloudfront-keyvaluestore", region_name="us-east-1"); key_name = f''test-key-{suffix}''; client.delete_key(Key=key_name)'
```

## Next steps

- Explore more operations with cloudfront key value store.
- Integrate with your applications.