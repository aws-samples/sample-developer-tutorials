import boto3, json, time
suffix = str(int(time.time()))[-6:]
client = boto3.client('transfer', region_name='us-east-1')
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'transfer-gs'}]
r = client.create_server(
    EndpointType='PUBLIC',
    IdentityProviderType='SERVICE_MANAGED',
    Protocols=['SFTP'],
    Tags=tags)
server_id = r['ServerId']
print(f"Created server: {server_id}")
# Wait for ONLINE
for _ in range(24):
    time.sleep(10)
    g = client.describe_server(ServerId=server_id)
    state = g['Server']['State']
    if state == 'ONLINE': break
print(f"State: {state}")
client.list_servers()
client.delete_server(ServerId=server_id)
print("Deleted. PASS")