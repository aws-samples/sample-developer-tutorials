import boto3
import time
import uuid

# Initialize the Image Builder client
client = boto3.client('imagebuilder', region_name='us-east-1')

# Generate a unique suffix for component names
suffix = str(int(time.time()))[-6:]

# List components
print("Listing components before creation...")
list_response = client.list_components(owner='Self', maxResults=10)
print(f"Listed components: {list_response}")

# Create a component
try:
    component_response = client.create_component(
        name=f'MyComponent-{suffix}',
        semanticVersion='1.0.0',
        description='My component description',
        changeDescription='Initial component creation',
        platform='Windows',
        format='SHELL',
        data='echo Hello, World!',
        kmsKeyId='alias/aws/s3',
        tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'imagebuilder-gs'}]
    )
    component_arn = component_response['componentBuildVersionArn']

    # Tag the component if necessary (some services require a separate call)
    client.tag_resource(resourceArn=component_arn, tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'imagebuilder-gs'}])

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")

# Clean up the created component
try:
    client.delete_component(componentBuildVersionArn=component_arn)
    print(f"Component {component_arn} deleted successfully.")
except Exception as e:
    print(f"Failed to delete component: {e}")