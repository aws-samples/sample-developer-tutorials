import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('marketplace-deployment', region_name='us-east-1')

try:
    print("Calling ListTagsForResource...")
    response = client.list_tags_for_resource(ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example')
    print(response)
    
    print("Calling PutDeploymentParameter...")
    response = client.put_deployment_parameter(
        ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example',
        ParameterName='example-param',
        ParameterValue='example-value'
    )
    print(response)
    
    resource_arn = f'arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example-{suffix}'
    print("Tagging resource...")
    client.tag_resource(
        ResourceArn=resource_arn,
        Tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'marketplace-deployment-gs'}]
    )
    
    print("Listing tags for tagged resource...")
    response = client.list_tags_for_resource(ResourceArn=resource_arn)
    print(response)
    
    print("Untagging resource...")
    client.untag_resource(
        ResourceArn=resource_arn,
        TagKeys=['project', 'tutorial']
    )
    
    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")

finally:
    try:
        print("Cleaning up created resources...")
        # Add cleanup logic if necessary
    except Exception as e:
        print(f"Cleanup error: {e}")