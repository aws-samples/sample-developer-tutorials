import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('controlcatalog', region_name='us-east-1')

try:
    print("Listing Domains:", client.list_domains())
    print("Listing Objectives:", client.list_objectives())
    print("Listing Controls:", client.list_controls())
    print("Listing Common Controls:", client.list_common_controls())
    print("Listing Control Mappings:", client.list_control_mappings())
    
    control_id = "example-control-id"  # Replace with a valid control ID
    print("Getting Control:", client.get_control(controlId=control_id))
    
    print("PASS")
except Exception as e:
    print("Error:", e)