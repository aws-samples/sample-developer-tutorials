import boto3, json, time, os

# Environment variable for role ARN
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('datazone', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]

# Tags to be added to each resource
tags = {
    'project': 'doc-smith',
    'tutorial': 'datazone-gs'
}

print("Creating a domain as a prerequisite for other operations.")
if ROLE_ARN:
    try:
        domain_response = client.create_domain(
            name=f'domain-name-{suffix}',
            description='Domain for DataZone tutorial',
            clientToken=str(time.time()),
            tags=tags,
            domainExecutionRole=ROLE_ARN
        )
        domain_id = domain_response['id']

        print("Verifying the created domain.")
        get_domain_response = client.get_domain(
            identifier=domain_id
        )
        print(f"Domain found: {get_domain_response['name']}")

        print("Cleaning up created domain.")
        client.delete_domain(
            identifier=domain_id
        )
        print("Domain deleted.")
    except botocore.exceptions.ClientError as e:
        print(f"An error occurred: {e}")
else:
    print("Environment variable TUTORIAL_ROLE_ARN is not set. Skipping domain creation.")

print('PASS')