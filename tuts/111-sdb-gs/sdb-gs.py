import boto3
import json
import time
import uuid

client = boto3.client('sdb', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
domain_name = f'test-domain-{suffix}'

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'sdb-gs'}]

print("Creating domain...")
client.create_domain(DomainName=domain_name, Tags=tags)
time.sleep(5)  # Wait for domain to become active

print("Verifying domain exists...")
domains = client.list_domains()
if 'Domains' in domains and domain_name not in [d['DomainName'] for d in domains['Domains']]:
    raise Exception("Domain not found")

item_name = f'item-{uuid.uuid4().hex[:8]}'
attributes = [
    {'Name': 'attr1', 'Value': 'value1', 'Replace': True},
    {'Name': 'attr2', 'Value': 'value2', 'Replace': True}
]

print("Putting attributes...")
client.put_attributes(DomainName=domain_name, ItemName=item_name, Attributes=attributes)

print("Deleting domain...")
client.delete_domain(DomainName=domain_name)
time.sleep(5)  # Wait for domain to be deleted

domains = client.list_domains()
if 'Domains' in domains and domain_name in [d['DomainName'] for d in domains['Domains']]:
    raise Exception("Domain not deleted")

print("PASS")