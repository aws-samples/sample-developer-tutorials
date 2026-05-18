import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('migrationhub-config', region_name='us-east-1')

try:
    print("Calling DescribeHomeRegionControls...")
    response = client.describe_home_region_controls()
    print(response)
    
    print("Calling GetHomeRegion...")
    response = client.get_home_region()
    print(response)
    
    home_region_control_id = f"test-control-{suffix}"
    
    print("Calling CreateHomeRegionControl...")
    response = client.create_home_region_control(
        HomeRegion='us-east-1',
        Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'migrationhub-config-gs'}]
    )
    print(response)
    
    print("Calling DescribeHomeRegionControls again...")
    response = client.describe_home_region_controls()
    print(response)
    
    print("Calling DeleteHomeRegionControl...")
    response = client.delete_home_region_control(
        ControlId=response['HomeRegionControls'][0]['ControlId']
    )
    print(response)
    
    print("PASS")
except Exception as e:
    print(f"Error: {e}")