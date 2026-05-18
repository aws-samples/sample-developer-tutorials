# Tutorial for Getting Started with Marketplace Deployment

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed

## Steps

1. **Set up your environment**

   Ensure you have Python and Boto3 installed. You can install Boto3 using pip:
   ```sh
   pip install boto3
   ```

2. **Import necessary libraries**

   ```python
   import boto3
   import time
   import random
   ```

3. **Create a unique suffix for resource names**

   ```python
   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   ```

4. **Initialize the Marketplace Deployment client**

   ```python
   client = boto3.client('marketplace-deployment', region_name='us-east-1')
   ```

5. **List tags for a resource**

   ```python
   try:
       print("Calling ListTagsForResource...")
       response = client.list_tags_for_resource(ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example')
       print(response)
   ```

6. **Put a deployment parameter**

   ```python
   print("Calling PutDeploymentParameter...")
   response = client.put_deployment_parameter(
       ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example',
       ParameterName='example-param',
       ParameterValue='example-value'
   )
   print(response)
   ```

7. **Tag a resource**

   ```python
   resource_arn = f'arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example-{suffix}'
   print("Tagging resource...")
   client.tag_resource(
       ResourceArn=resource_arn,
       Tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'marketplace-deployment-gs'}]
   )
   ```

8. **List tags for the tagged resource**

   ```python
   print("Listing tags for tagged resource...")
   response = client.list_tags_for_resource(ResourceArn=resource_arn)
   print(response)
   ```

9. **Untag a resource**

   ```python
   print("Untagging resource...")
   client.untag_resource(
       ResourceArn=resource_arn,
       TagKeys=['project', 'tutorial']
   )
   ```

10. **Handle exceptions**

    ```python
    except Exception as e:
        print(f"An error occurred: {e}")
    ```

11. **Clean up created resources**

    ```python
    finally:
        try:
            print("Cleaning up created resources...")
            # Add cleanup logic if necessary
        except Exception as e:
            print(f"Cleanup error: {e}")
    ```

## Clean up
Delete any resources created to avoid unnecessary charges.

## Next steps
Explore more features of the AWS Marketplace Deployment service by reviewing the [official documentation](https://docs.aws.amazon.com/marketplace).