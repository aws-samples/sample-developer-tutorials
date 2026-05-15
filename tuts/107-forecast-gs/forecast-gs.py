import boto3
import time
import random
import string

# Initialize the Forecast client
client = boto3.client('forecast', region_name='us-east-1')

# Generate a unique suffix for the dataset group name
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
dataset_group_name = f'm{suffix}'
domain = 'RETAIL'

print(f"Creating Dataset Group with name: {dataset_group_name}")
try:
    r = client.create_dataset_group(DatasetGroupName=dataset_group_name, Domain=domain, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'forecast-gs'}])
    dataset_group_arn = r['DatasetGroupArn']
    print(f"Dataset Group created with ARN: {dataset_group_arn}")

    print("Describing the Dataset Group")
    client.describe_dataset_group(DatasetGroupArn=dataset_group_arn)

    print("Listing all Dataset Groups")
    client.list_dataset_groups()

    print(f"Deleting Dataset Group with ARN: {dataset_group_arn}")
    client.delete_dataset_group(DatasetGroupArn=dataset_group_arn)
    print("Dataset Group deleted")
except client.exceptions.ClientError as e:
    if 'DatasetGroupArn' in locals():
        try:
            client.delete_dataset_group(DatasetGroupArn=dataset_group_arn)
        except:
            pass
    print(e)
    print("FAIL")
else:
    print("PASS")