# Amazon AWS Pricing Tutorial

## Prerequisites

- An [AWS account](https://aws.amazon.com/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
- Python installed with `boto3` library

## Steps

### 1. Initialize a session using Amazon AWS Pricing

```python
import boto3
import uuid

# Initialize a session using Amazon AWS Pricing
session = boto3.Session(
    aws_access_key_id='YOUR_ACCESS_KEY',
    aws_secret_access_key='YOUR_SECRET_KEY',
    region_name='us-east-1'
)

client = session.client('pricing', region_name='us-east-1')
```

### 2. Describe services

**DescribeServices operation**

```bash
$ response = client.describe_services(
    ServiceCode='AmazonEC2',
    FormatVersion='aws_v1'
)
$ print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
```

### 3. Get attribute values

**GetAttributeValues operation**

```bash
$ response = client.get_attribute_values(
    ServiceCode='AmazonEC2',
    AttributeName='volumeType',
    NextToken=''
)
$ print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
```

### 4. Get price list file url

**GetPriceListFileUrl operation**

```bash
$ response = client.get_price_list_file_url(
    ServiceCode='AmazonEC2',
    Region='us-east-1',
    FileFormat='JSON'
)
$ print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
```

### 5. Get products

**GetProducts operation**

```bash
$ response = client.get_products(
    ServicesCodes=['AmazonEC2'],
    MaxResults=10,
    Filters=[
        {
            'Type': 'TERM_MATCH',
            'Field': 'volumeType',
            'Value': 'gp2'
        }
    ]
)
$ print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
```

### 6. List price lists

**ListPriceLists operation**

```bash
$ response = client.list_price_lists(
    ServiceCode='AmazonEC2',
    Region='us-east-1',
    NextToken=''
)
$ print("Status:", response['ResponseMetadata']['HTTPStatusCode'])
```

### 7. Add tags to a resource

```python
# Adding tags to a resource (example, assuming resource ARN is known)
resource_arn = 'arn:aws:pricing:us-east-1:123456789012:resource/example'
client.tag_resource(
    ResourceArn=resource_arn,
    Tags=[
        {'Key': 'project', 'Value': 'doc-smith'},
        {'Key': 'tutorial', 'Value': 'pricing-gs'}
    ]
)
```

## Clean up

Remove any resources or configurations created during this tutorial to avoid unnecessary costs.

## Next steps

Explore more AWS Pricing features and integrate them into your applications.