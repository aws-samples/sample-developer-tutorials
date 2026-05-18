import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('connect', region_name='us-east-1')

try:
    instance_id = 'your-instance-id'
    contact_id = 'your-contact-id'
    
    response = client.list_realtime_contact_analysis_segments(
        InstanceId=instance_id,
        ContactId=contact_id
    )
    
    print(response)
    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")