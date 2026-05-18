# Tutorial for Getting Started with Bedrock Data Automation Runtime

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed

## Steps

1. **Set up your environment**

   Ensure you have the necessary tools installed:
   ```sh
   pip install boto3
   ```

2. **Import Boto3 and configure the client**

   ```python
   import boto3
   import time
   import random

   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('bedrock-data-automation-runtime', region_name='us-east-1')
   ```

3. **List tags for a resource**

   ```python
   try:
       print("Calling ListTagsForResource...")
       response = client.list_tags_for_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example')
       print(response)
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

4. **Get data automation status**

   ```python
   try:
       print("Calling GetDataAutomationStatus...")
       response = client.get_data_automation_status(AutomationId='example-automation-id')
       print(response)
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

5. **Invoke data automation**

   ```python
   try:
       print("Invoking Data Automation...")
       response = client.invoke_data_automation(AutomationId='example-automation-id', InputParameters='{"key": "value"}')
       print(response)
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

6. **Tag a resource**

   ```python
   try:
       print("Tagging a resource...")
       response = client.tag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'bedrock-data-automation-runtime-gs'}])
       print(response)
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

7. **Untag a resource**

   ```python
   try:
       print("Untagging a resource...")
       response = client.untag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', TagKeys=['project', 'tutorial'])
       print(response)
   except Exception as e:
       print(f"An error occurred: {e}")
   ```

## Clean up

Delete any resources created to avoid unnecessary charges.

```python
finally:
    print("Cleaning up any created resources...")
    try:
        client.untag_resource(ResourceArn='arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example', TagKeys=['project', 'tutorial'])
    except:
        pass
```

## Next steps

Explore more features of Bedrock Data Automation Runtime by referring to the [official AWS documentation](https://docs.aws.amazon.com/).