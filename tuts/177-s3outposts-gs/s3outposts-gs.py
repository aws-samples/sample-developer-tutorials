import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('s3outposts', region_name='us-east-1')

try:
    print("Listing Outposts with S3:")
    response = client.list_outposts_with_s3()
    print(response)

    print("Listing Endpoints:")
    response = client.list_endpoints()
    print(response)

    print("Listing Shared Endpoints:")
    response = client.list_shared_endpoints()
    print(response)

    endpoint_name = f"endpoint-{suffix}"
    outpost_id = "op-1234567890abcdef0"  # Replace with a valid Outpost ID

    print("Creating Endpoint:")
    response = client.create_endpoint(
        EndpointName=endpoint_name,
        OutpostId=outpost_id,
        SecurityGroupId="sg-12345678",  # Replace with a valid Security Group ID
        SubnetId="subnet-12345678",  # Replace with a valid Subnet ID
        Tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'s3outposts-gs'}]
    )
    print(response)

    time.sleep(10)  # Wait for the endpoint to be created

    print("Listing Endpoints after creation:")
    response = client.list_endpoints()
    print(response)

    print("Deleting Endpoint:")
    response = client.delete_endpoint(EndpointName=endpoint_name)
    print(response)

    time.sleep(10)  # Wait for the endpoint to be deleted

    print("Listing Endpoints after deletion:")
    response = client.list_endpoints()
    print(response)

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")