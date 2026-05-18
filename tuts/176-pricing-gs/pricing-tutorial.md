# Tutorial for Getting Started with AWS Pricing

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed

## Steps

1. **Set up your environment**

   Ensure you have AWS credentials configured and Boto3 installed.

   ```bash
   pip install boto3
   ```

2. **Import necessary libraries**

   ```python
   import boto3
   import time
   import random
   ```

3. **Initialize the Pricing client**

   ```python
   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('pricing', region_name='us-east-1')
   ```

4. **List Price Lists**

   ```python
   try:
       print("Calling ListPriceLists...")
       response = client.list_price_lists()
       print(response)
   ```

5. **Describe Services**

   ```python
       print("Calling DescribeServices...")
       response = client.describe_services(ServiceCode='AmazonEC2')
       print(response)
   ```

6. **Get Attribute Values**

   ```python
       print("Calling GetAttributeValues...")
       response = client.get_attribute_values(ServiceCode='AmazonEC2', AttributeName='volumeType')
       print(response)
   ```

7. **Get Price List File URL**

   ```python
       print("Calling GetPriceListFileUrl...")
       response = client.get_price_list_file_url(FileFormat='JSON', CompressionFormat='GZIP', ServiceCode='AmazonEC2')
       print(response)
   ```

8. **Get Products**

   ```python
       print("Calling GetProducts...")
       response = client.get_products(ServiceCode='AmazonEC2', Filters=[{'Type': 'TERM_MATCH', 'Field': 'volumeType', 'Value': 'gp2'}])
       print(response)

       print("PASS")
   except Exception as e:
       print("Error:", e)
   ```

## Clean up

No resources are created in this tutorial that need deletion.

## Next steps

Explore more features of the AWS Pricing API by checking the [official documentation](https://docs.aws.amazon.com/aws-cost-management/latest/userguide/what-is-cost-management.html).