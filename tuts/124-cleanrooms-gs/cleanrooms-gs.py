import boto3, json, time, uuid

client = boto3.client('cleanrooms', region_name='us-east-1')
account_id = boto3.client('sts').get_caller_identity()['Account']
suffix = str(int(time.time()))[-6:]
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'cleanrooms-gs'}]

# Create Collaboration
r = client.create_collaboration(
    name=f'collab-{suffix}', 
    description='Test collaboration',
    creatorMemberAbilities=['CAN_QUERY', 'CAN_RECEIVE_RESULTS'],
    creatorDisplayName='DocBabu',
    members=[],
    queryLogStatus='DISABLED',
    tags=tags)
collab_id = r['collaboration']['id']
print("Collaboration created:", collab_id)

# Verify Collaboration
collab_details = client.get_collaboration(collaborationIdentifier=collab_id)
print("Collaboration verified:", collab_details['collaboration']['name'])

# List Collaborations
collabs = client.list_collaborations()
print("Listed collaborations:", len(collabs['collaborationList']))

# Clean up
client.delete_collaboration(collaborationIdentifier=collab_id)
print("Collaboration deleted")

print("PASS")