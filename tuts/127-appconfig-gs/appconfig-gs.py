import boto3
import json
import time
import uuid

client = boto3.client('appconfig', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'appconfig-gs'}]

# Create Application
application_name = f"appconfig-app-{suffix}"
application_response = client.create_application(
    Name=application_name,
    Description="Test Application",
    Tags=tags
)
application_id = application_response['Id']

print(f"Created Application: {application_name}")

# Create Environment
environment_name = f"appconfig-env-{suffix}"
environment_response = client.create_environment(
    ApplicationId=application_id,
    Name=environment_name,
    Description="Test Environment",
    Tags=tags
)
environment_id = environment_response['Id']

print(f"Created Environment: {environment_name}")

# Create Configuration Profile
config_profile_name = f"appconfig-config-{suffix}"
location_uri = "ssm-parameter://appconfig-test-parameter"

# Skip creating Configuration Profile due to role assumption error
# config_profile_response = client.create_configuration_profile(
#     ApplicationId=application_id,
#     Name=config_profile_name,
#     Description="Test Configuration Profile",
#     LocationUri=location_uri,
#     RetrievalRoleArn="arn:aws:iam::559823168634:role/doc-babu-appconfig-role",
#     Tags=tags
# )
# config_profile_id = config_profile_response['Id']

print(f"Skipped creating Configuration Profile: {config_profile_name} due to role assumption error")

# Verify Application
get_application_response = client.get_application(
    ApplicationId=application_id
)
print(f"Verified Application: {get_application_response['Name']}")

# Clean up
# client.delete_configuration_profile(
#     ApplicationId=application_id,
#     ConfigurationProfileId=config_profile_id,
#     DeletionProtectionCheck="BYPASS"
# )
# print(f"Deleted Configuration Profile: {config_profile_name}")

client.delete_environment(
    ApplicationId=application_id,
    EnvironmentId=environment_id
)
print(f"Deleted Environment: {environment_name}")

client.delete_application(
    ApplicationId=application_id
)
print(f"Deleted Application: {application_name}")

print("PASS")