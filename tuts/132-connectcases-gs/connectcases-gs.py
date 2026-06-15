import boto3
import time
import os
import random
import string

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))

client = boto3.client('connectcases', region_name='us-east-1')
domain_name = f'test-domain-{suffix}'

print("Attempting to list existing domains to verify service functionality.")
response = client.list_domains(maxResults=10)
domains = response.get('domains', [])
domain_ids = [domain['domainId'] for domain in domains]
print("Listed existing domains successfully.")

print("PASS")