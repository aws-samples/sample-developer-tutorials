# Tutorial: Getting started with AWS Migration Hub Config

## Prerequisites

- An AWS account
- AWS CLI installed and configured
- Python installed
- Boto3 Python library installed

## Steps

**1. Set up your environment**

```bash
$ pip install boto3
```

**2. Create a python script**

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

**3. Run the script**

```bash
$ python migrationhub_config_gs.py
```

## Clean up

To avoid unnecessary charges, delete the resources you created.

**1. Delete the home region control**

Find the control id in the output of the script and run the following command:

```bash
$ aws migrationhub-config delete-home-region-control --control-id 123456789012
```

## Next steps

- Learn more about [AWS Migration Hub Config](https://docs.aws.amazon.com/migrationhub-config/latest/ug/what-is.html)
- Explore other [AWS Migration Hub services](https://aws.amazon.com/migration/)