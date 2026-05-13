import boto3
import time

# Initialize the Pinpoint client
client = boto3.client('pinpoint', region_name='us-east-1')

# Generate a unique suffix for the application name
suffix = str(int(time.time()))[-6:]
app_name = f'my-app-{suffix}'

print(f"Creating Pinpoint application with name: {app_name}")
# Create a Pinpoint application
r = client.create_app(
    CreateApplicationRequest={
        'Name': app_name
    }
)
app_id = r['ApplicationResponse']['Id']
print(f"Pinpoint application created with ID: {app_id}")

print("Retrieving the newly created application")
# Retrieve the newly created application
client.get_app(ApplicationId=app_id)

print("Listing all applications")
# List all applications
client.get_apps()

print(f"Deleting Pinpoint application with ID: {app_id}")
# Delete the Pinpoint application
client.delete_app(ApplicationId=app_id)
print("PASS")