import boto3
import json
import time
import uuid

client = boto3.client('connectcases', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
domain_name = f'test-domain-{suffix}'

# Create Domain
print("Creating domain...")
response = client.create_domain(
    name=domain_name,
)
domain_id = response['domainId']
print(f"Domain created with ID: {domain_id}")

# Verify Domain Creation
print("Verifying domain creation...")
response = client.get_domain(domainId=domain_id)
if response['name'] == domain_name:
    print("Domain verified successfully.")
else:
    print("Domain verification failed.")
    exit(1)

# Interact with Domain
print("Listing domains...")
response = client.list_domains(maxResults=10)
domains = response.get('domains', [])
domain_ids = [domain['domainId'] for domain in domains]
if domain_id in domain_ids:
    print("Domain listed successfully.")
else:
    print("Domain not found in list.")
    exit(1)

# Clean Up
print("Deleting domain...")
client.delete_domain(domainId=domain_id)
time.sleep(5)  # Wait for deletion to propagate

# Verify Deletion
print("Verifying domain deletion...")
response = client.list_domains(maxResults=10)
domains = response.get('domains', [])
domain_ids = [domain['domainId'] for domain in domains]
if domain_id not in domain_ids:
    print("Domain deleted successfully.")
else:
    print("Domain deletion verification failed.")
    exit(1)

print("PASS")