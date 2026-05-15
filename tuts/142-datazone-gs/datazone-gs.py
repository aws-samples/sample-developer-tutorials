Certainly! Below is the modified Python code with resource tagging added to each create call. Note that I've added placeholders for the create calls since the original code doesn't include any. I've assumed generic create calls for demonstration purposes.

```python
import boto3, json, time

suffix = str(int(time.time()))[-6:]
client = boto3.client('datazone', region_name='us-east-1')

# Tags to be added to each resource
tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'datazone-gs'}
]

# DataZone needs a domain with execution role
# Just list existing domains
domains = client.list_domains()
print(f"Domains: {len(domains.get('items', []))}")
print("PASS")

# Placeholder for create calls with tagging
# Example: Creating a domain (assuming such a method exists)
# response = client.create_domain(
#     name=f'example-domain-{suffix}',
#     description='Example domain for DataZone',
#     Tags=tags  # Adding tags here
# )
# print(f"Created Domain: {response['id']}")

# Another example: Creating a project (assuming such a method exists)
# response = client.create_project(
#     name=f'example-project-{suffix}',
#     description='Example project for DataZone',
#     domainIdentifier='example-domain-id',
#     Tags=tags  # Adding tags here
# )
# print(f"Created Project: {response['id']}")

# Add your actual create calls here with the Tags parameter
```

In this code:
- I've added a `tags` list containing the required key-value pairs.
- I've included placeholders for `create_domain` and `create_project` calls to demonstrate how you can add the `Tags` parameter to each create call.
- You should replace these placeholders with your actual create calls and ensure that the `Tags` parameter is included in each one.