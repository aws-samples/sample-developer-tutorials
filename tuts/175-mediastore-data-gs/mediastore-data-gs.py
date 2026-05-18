import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('mediastore-data', region_name='us-east-1')

try:
    response = client.list_items(ContainerName='example-container')
    print("ListItems:", response)
    
    object_name = 'example-object'
    response = client.describe_object(ContainerName='example-container', Path=f'/{object_name}')
    print("DescribeObject:", response)
    
    response = client.get_object(ContainerName='example-container', Path=f'/{object_name}')
    print("GetObject:", response)
    
    object_name_with_suffix = f'example-object-{suffix}'
    with open('example-file.txt', 'rb') as file_data:
        client.put_object(ContainerName='example-container', Path=f'/{object_name_with_suffix}', Body=file_data, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'mediastore-data-gs'}])
    
    response = client.describe_object(ContainerName='example-container', Path=f'/{object_name_with_suffix}')
    print("DescribeObject (new):", response)
    
    client.delete_object(ContainerName='example-container', Path=f'/{object_name_with_suffix}')
    
    print("PASS")
except Exception as e:
    print("Error:", e)