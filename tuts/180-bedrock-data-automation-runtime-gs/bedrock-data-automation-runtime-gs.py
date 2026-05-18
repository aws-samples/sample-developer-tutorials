import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('bedrock-data-automation-runtime', region_name='us-east-1')

try:
    print("Calling ListTagsForResource...")
    response = client.list_tags_for_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example')
    print(response)

    print("Calling GetDataAutomationStatus...")
    response = client.get_data_automation_status(AutomationId='example-automation-id')
    print(response)

    print("Invoking Data Automation...")
    response = client.invoke_data_automation(AutomationId='example-automation-id', InputParameters='{"key": "value"}')
    print(response)

    print("Tagging a resource...")
    response = client.tag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'bedrock-data-automation-runtime-gs'}])
    print(response)

    print("Untagging a resource...")
    response = client.untag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', TagKeys=['project', 'tutorial'])
    print(response)

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")

finally:
    print("Cleaning up any created resources...")
    try:
        client.untag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', TagKeys=['project', 'tutorial'])
    except:
        pass