import boto3
import uuid

# Initialize a session using Amazon AWS Pricing
session = boto3.Session(
    aws_access_key_id='YOUR_ACCESS_KEY',
    aws_secret_access_key='YOUR_SECRET_KEY',
    region_name='us-east-1'
)

client = session.client('pricing', region_name='us-east-1')

# Unique suffix for names
unique_suffix = str(uuid.uuid4())[:8]

# DescribeServices operation
print("DescribeServices operation:")
response = client.describe_services(
    ServiceCode='AmazonEC2',
    FormatVersion='aws_v1'
)
print("Status:", response['ResponseMetadata']['HTTPStatusCode'])

# GetAttributeValues operation
print("\nGetAttributeValues operation:")
response = client.get_attribute_values(
    ServiceCode='AmazonEC2',
    AttributeName='volumeType',
    NextToken=''
)
print("Status:", response['ResponseMetadata']['HTTPStatusCode'])

# GetPriceListFileUrl operation
print("\nGetPriceListFileUrl operation:")
response = client.get_price_list_file_url(
    ServiceCode='AmazonEC2',
    Region='us-east-1',
    FileFormat='JSON'
)
print("Status:", response['ResponseMetadata']['HTTPStatusCode'])

# GetProducts operation
print("\nGetProducts operation:")
response = client.get_products(
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
print("Status:", response['ResponseMetadata']['HTTPStatusCode'])

# ListPriceLists operation
print("\nListPriceLists operation:")
response = client.list_price_lists(
    ServiceCode='AmazonEC2',
    Region='us-east-1',
    NextToken=''
)
print("Status:", response['ResponseMetadata']['HTTPStatusCode'])

# Adding tags to a resource (example, assuming resource ARN is known)
resource_arn = 'arn:aws:pricing:us-east-1:123456789012:resource/example'
client.tag_resource(
    ResourceArn=resource_arn,
    Tags=[
        {'Key': 'project', 'Value': 'doc-smith'},
        {'Key': 'tutorial', 'Value': 'pricing-gs'}
    ]
)

print("PASS")