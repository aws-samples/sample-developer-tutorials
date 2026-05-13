import boto3
import json
import time
import uuid

client = boto3.client('verifiedpermissions', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
policy_store_name = f'policy-store-{suffix}'
client_token = uuid.uuid4().hex[:8]

print("Creating Policy Store...")
create_response = client.create_policy_store(
    clientToken=client_token,
    validationSettings={
        'mode': 'STRICT'
    },
    description='Test Policy Store',
    deletionProtection='DISABLED'
)
policy_store_id = create_response['policyStoreId']
print(f"Policy Store created with ID: {policy_store_id}")

print("Verifying Policy Store exists...")
while True:
    try:
        get_response = client.get_policy_store(
            policyStoreId=policy_store_id
        )
        print("Policy Store verified.")
        break
    except client.exceptions.ResourceNotFoundException:
        print("Policy Store not yet available, waiting...")
        time.sleep(5)

print("Listing Policy Stores to confirm creation...")
list_response = client.list_policy_stores()
policy_stores = list_response['policyStores']
found = any(ps['policyStoreId'] == policy_store_id for ps in policy_stores)
if found:
    print("Policy Store listed successfully.")
else:
    print("Policy Store not found in list.")

print("Deleting Policy Store...")
client.delete_policy_store(
    policyStoreId=policy_store_id
)
print("Verifying Policy Store deletion...")
while True:
    try:
        client.get_policy_store(
            policyStoreId=policy_store_id
        )
        print("Policy Store still exists, waiting...")
        time.sleep(5)
    except client.exceptions.ResourceNotFoundException:
        print("Policy Store successfully deleted.")
        break

print("PASS")