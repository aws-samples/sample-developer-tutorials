# Tutorial for Getting Started with Migrationhub Config

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

2. **Create a Python script**

   Create a file named `migrationhub_config_gs.py` and add the following content:
   ```python
   import boto3
   import time
   import random

   suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
   client = boto3.client('migrationhub-config', region_name='us-east-1')

   try:
       print("Calling DescribeHomeRegionControls...")
       response = client.describe_home_region_controls()
       print(response)
       
       print("Calling GetHomeRegion...")
       response = client.get_home_region()
       print(response)
       
       home_region_control_id = f"test-control-{suffix}"
       
       print("Calling CreateHomeRegionControl...")
       response = client.create_home_region_control(
           HomeRegion='us-east-1',
           Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'migrationhub-config-gs'}]
       )
       print(response)
       
       print("Calling DescribeHomeRegionControls again...")
       response = client.describe_home_region_controls()
       print(response)
       
       print("Calling DeleteHomeRegionControl...")
       response = client.delete_home_region_control(
           ControlId=response['HomeRegionControls'][0]['ControlId']
       )
       print(response)
       
       print("PASS")
   except Exception as e:
       print(f"Error: {e}")
   ```

3. **Run the script**

   Execute the script using Python.
   ```bash
   python migrationhub_config_gs.py
   ```

## Clean up

Ensure you delete any resources created to avoid unnecessary charges.
```python
response = client.delete_home_region_control(
    ControlId=response['HomeRegionControls'][0]['ControlId']
)
```

## Next steps

Explore more features of AWS Migration Hub Config by visiting the [official documentation](https://docs.aws.amazon.com/migrationhub/latest/ug/what-is-hub.html).