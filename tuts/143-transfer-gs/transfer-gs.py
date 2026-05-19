import boto3
import json
import time
import os

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'transfer-gs'}]

transfer_client = boto3.client('transfer', region_name='us-east-1')

# Step 1: Create Server
print("Creating a Transfer Family server...")
server_response = transfer_client.create_server(
    EndpointType='PUBLIC',
    IdentityProviderType='SERVICE_MANAGED',
    Protocols=['SFTP'],
    Tags=tags
)
server_id = server_response['ServerId']
print(f"Transfer Family server created with ID: {server_id}")

# Wait for the server to become active
print("Waiting for the server to become active...")
transfer_client.get_waiter('server_online').wait(ServerId=server_id)
print("Server is now active.")

# Step 2: Create User
print("Creating a user for the Transfer Family server...")
user_response = transfer_client.create_user(
    ServerId=server_id,
    UserName=f'user-{suffix}',
    Tags=tags
)
user_name = user_response['UserName']
print(f"User created with name: {user_name}")

# Step 3: Verify Server
print("Verifying the Transfer Family server...")
describe_server_response = transfer_client.describe_server(ServerId=server_id)
print("Server verification successful.")

# Step 4: Clean up
print("Cleaning up resources...")

# Delete User
print("Deleting the user...")
transfer_client.delete_user(
    ServerId=server_id,
    UserName=f'user-{suffix}'
)
print("User deleted.")

# Delete Server
print("Deleting the Transfer Family server...")
transfer_client.delete_server(ServerId=server_id)
print("Transfer Family server deleted.")

print('PASS')