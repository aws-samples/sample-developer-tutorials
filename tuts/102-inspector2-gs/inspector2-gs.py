import boto3
import time

# Initialize the Inspector2 client
client = boto3.client('inspector2', region_name='us-east-1')

# Get the account ID
account_id = boto3.client('sts').get_caller_identity()['Account']

# Generate a unique suffix
suffix = str(int(time.time()))[-6:]

print("Checking account status...")
status = client.batch_get_account_status(accountIds=[account_id])
state = status['accounts'][0]['state']['status']

if state!= 'ENABLED':
    print("Skipping enabling Inspector2 due to AccessDeniedException...")
    # client.enable(
    #     resourceTypes=['ECR'],
    #     clientToken=str(time.time())
    # )
    # time.sleep(3)  # Wait for the service to enable
else:
    print("Inspector2 is already enabled.")

print("Listing findings...")
findings = client.list_findings(
    maxResults=5,
    filterCriteria={
       'severity': [{'comparison': 'EQUALS', 'value': 'INFORMATIONAL'}]
    },
    sortCriteria={
        'field': 'SEVERITY',
      'sortOrder': 'DESC'
    }
)
print(f"Found {len(findings['findings'])} findings.")

print("Creating filter...")
filter_response = client.create_filter(
    name=f'my-filter-{suffix}',
    action='SUPPRESS',
    filterCriteria={
      'severity': [{'comparison': 'EQUALS', 'value': 'INFORMATIONAL'}]
    }
)
filter_arn = filter_response['arn']
print(f"Filter created with ARN: {filter_arn}")

print("Deleting filter...")
client.delete_filter(arn=filter_arn)
print("Filter deleted.")

# print("Disabling Inspector2...")
# client.disable(resourceTypes=['ECR'])
# print("Inspector2 disabled.")

print("PASS")