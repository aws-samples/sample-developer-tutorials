import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('pricing', region_name='us-east-1')

try:
    print("Calling ListPriceLists...")
    response = client.list_price_lists()
    print(response)

    print("Calling DescribeServices...")
    response = client.describe_services(ServiceCode='AmazonEC2')
    print(response)

    print("Calling GetAttributeValues...")
    response = client.get_attribute_values(ServiceCode='AmazonEC2', AttributeName='volumeType')
    print(response)

    print("Calling GetPriceListFileUrl...")
    response = client.get_price_list_file_url(FileFormat='JSON', CompressionFormat='GZIP', ServiceCode='AmazonEC2')
    print(response)

    print("Calling GetProducts...")
    response = client.get_products(ServiceCode='AmazonEC2', Filters=[{'Type': 'TERM_MATCH', 'Field': 'volumeType', 'Value': 'gp2'}])
    print(response)

    print("PASS")
except Exception as e:
    print("Error:", e)