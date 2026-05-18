import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('bcm-recommended-actions', region_name='us-east-1')

try:
    response = client.list_recommended_actions()
    print(response)
    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")