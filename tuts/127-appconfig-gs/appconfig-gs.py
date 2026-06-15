import boto3
import json
import time
import os
import random
import string

client = boto3.client('appconfig', region_name='us-east-1')
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
tags = {'project': 'doc-smith', 'tutorial': 'appconfig-gs'}

print("Creating an application...")
application_name = f"appconfig-app-{suffix}"
application_response = client.create_application(
    Name=application_name,
    Description="Test Application",
    Tags=tags
)
application_id = application_response['Id']
print(f"Created Application: {application_name}")

print("Creating an environment...")
environment_name = f"appconfig-env-{suffix}"
environment_response = client.create_environment(
    ApplicationId=application_id,
    Name=environment_name,
    Description="Test Environment",
    Tags=tags
)
environment_id = environment_response['Id']
print(f"Created Environment: {environment_name}")

print("Creating a configuration profile...")
config_profile_name = f"appconfig-config-{suffix}"
location_uri = "ssm-parameter://appconfig-test-parameter"

if ROLE_ARN:
    config_profile_response = client.create_configuration_profile(
        ApplicationId=application_id,
        Name=config_profile_name,
        Description="Test Configuration Profile",
        LocationUri=location_uri,
        RetrievalRoleArn=ROLE_ARN,
        Tags=tags
    )
    config_profile_id = config_profile_response['Id']
    print(f"Created Configuration Profile: {config_profile_name}")
else:
    print(f"Skipped creating Configuration Profile: {config_profile_name} due to missing role ARN")

print("Verifying resources...")
time.sleep(10)  # Wait for resources to be available

get_application_response = client.get_application(ApplicationId=application_id)
print(f"Verified Application: {get_application_response['Name']}")

if ROLE_ARN:
    get_config_profile_response = client.get_configuration_profile(ApplicationId=application_id, ConfigurationProfileId=config_profile_id)
    print(f"Verified Configuration Profile: {get_config_profile_response['Name']}")

get_environment_response = client.get_environment(ApplicationId=application_id, EnvironmentId=environment_id)
print(f"Verified Environment: {get_environment_response['Name']}")

print("Cleaning up...")

client.delete_environment(
    ApplicationId=application_id,
    EnvironmentId=environment_id
)
print(f"Deleted Environment: {environment_name}")

if ROLE_ARN:
    client.delete_configuration_profile(
        ApplicationId=application_id,
        ConfigurationProfileId=config_profile_id
    )
    print(f"Deleted Configuration Profile: {config_profile_name}")

client.delete_application(
    ApplicationId=application_id
)
print(f"Deleted Application: {application_name}")

print("PASS")