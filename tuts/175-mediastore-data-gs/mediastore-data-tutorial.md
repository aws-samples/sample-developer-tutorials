# Tutorial: Interacting with AWS Elemental MediaStore using Boto3

## Prerequisites

- An AWS account.
- AWS CLI configured with appropriate credentials.
- Python installed with `boto3` library.
- An existing AWS Elemental MediaStore container.

## Steps

### 1. List Items in the Container

**List Items**

```bash
$ python -c 'import boto3; client = boto3.client("mediastore-data", region_name="us-east-1"); response = client.list_items(ContainerName="example-container"); print("ListItems:", response)'
```

**Expected Output**

```json
ListItems: {'Items': [{'Name': 'example-object', 'Type': 'OBJECT', 'ContentType': 'application/octet-stream'}], 'ResponseMetadata': {'RequestId': '12345678-90ab-cdef-1234-567890abcdef', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '12345678-90ab-cdef-1234-567890abcdef', 'content-type': 'application/json'}, 'RetryAttempts': 0}}
```

### 2. Describe an Object

**Describe Object**

```bash
$ python -c 'import boto3; client = boto3.client("mediastore-data", region_name="us-east-1"); response = client.describe_object(ContainerName="example-container", Path="/example-object"); print("DescribeObject:", response)'
```

**Expected Output**

```json
DescribeObject: {'CacheControl':'max-age=31536000', 'ContentType': 'application/octet-stream', 'ETag': '"1234567890abcdef1234567890abcdef1234567890ab"', 'LastModified': datetime.datetime(2023, 10, 2, 12, 34, 56, tzinfo=tzutc()), 'ResponseMetadata': {'RequestId': '12345678-90ab-cdef-1234-567890abcdef', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '12345678-90ab-cdef-1234-567890abcdef', 'content-type': 'application/json'}, 'RetryAttempts': 0}}
```

### 3. Get an Object

**Get Object**

```bash
$ python -c 'import boto3; client = boto3.client("mediastore-data", region_name="us-east-1"); response = client.get_object(ContainerName="example-container", Path="/example-object"); print("GetObject:", response)'
```

**Expected Output**

```json
GetObject: {'Body': <botocore.response.StreamingBody object at 0x1234567890ab>, 'CacheControl':'max-age=31536000', 'ContentType': 'application/octet-stream', 'ETag': '"1234567890abcdef1234567890abcdef1234567890ab"', 'LastModified': datetime.datetime(2023, 10, 2, 12, 34, 56, tzinfo=tzutc()), 'ResponseMetadata': {'RequestId': '12345678-90ab-cdef-1234-567890abcdef', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '12345678-90ab-cdef-1234-567890abcdef', 'content-type': 'application/octet-stream'}, 'RetryAttempts': 0}}
```

### 4. Put an Object with a Suffix

**Put Object**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("mediastore-data", region_name="us-east-1"); with open("example-file.txt", "rb") as file_data: response = client.put_object(ContainerName="example-container", Path=f"/example-object-{suffix}", Body=file_data, Tags=[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"mediastore-data-gs"}]); print("PutObject:", response)'
```

**Expected Output**

```json
PutObject: {'ResponseMetadata': {'RequestId': '12345678-90ab-cdef-1234-567890abcdef', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '12345678-90ab-cdef-1234-567890abcdef', 'content-type': 'application/json'}, 'RetryAttempts': 0}}
```

### 5. Describe the New Object

**Describe New Object**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("mediastore-data", region_name="us-east-1"); response = client.describe_object(ContainerName="example-container", Path=f"/example-object-{suffix}"); print("DescribeObject (new):", response)'
```

**Expected Output**

```json
DescribeObject (new): {'CacheControl':'max-age=31536000', 'ContentType': 'application/octet-stream', 'ETag': '"1234567890abcdef1234567890abcdef1234567890ab"', 'LastModified': datetime.datetime(2023, 10, 2, 12, 34, 56, tzinfo=tzutc()), 'ResponseMetadata': {'RequestId': '12345678-90ab-cdef-1234-567890abcdef', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': '12345678-90ab-cdef-1234-567890abcdef', 'content-type': 'application/json'}, 'RetryAttempts': 0}}
```

### 6. Delete the New Object

**Delete Object**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client("mediastore-data", region_name="us-east-1"); client.delete_object(ContainerName="example-container", Path=f"/example-object-{suffix}"); print("Object deleted")'
```

**Expected Output**

```plaintext
Object deleted
```

## Clean Up

- Ensure that all objects created during this tutorial are deleted to avoid unnecessary costs.

## Next Steps

- Explore more AWS Elemental MediaStore features.
- Integrate MediaStore with other AWS services for a complete media workflow.