# Aws billingconductor custom line item tutorial

## Prerequisites

- Aws account
- Aws cli configured with appropriate permissions
- Python installed with boto3 library

## Steps

**1. Initialize the boto3 client**

```python
import boto3

client = boto3.client('billingconductor', region_name='us-east-1')
```

**2. Generate a unique suffix for resource names**

```python
import time

suffix = str(int(time.time()))[-6:]
resource_name = f"billing-view-{suffix}"
```

**3. Define the source views**

```python
source_views = [
    "arn:aws:billingconductor::123456789012:billingview/source-view-1",
    "arn:aws:billingconductor::123456789012:billingview/source-view-2"
]
```

**4. Create a custom line item**

```python
response = client.create_custom_line_item(
    name=resource_name,
    description="Test custom line item",
    billingPeriodRange={
        'ExclusiveEndBillingPeriod': "2024-05",
        'InclusiveStartBillingPeriod': "2024-03"
    },
    billingGroupArn="arn:aws:billingconductor::123456789012:billinggroup/test-billing-group",
    customLineItemChargeDetails={
        'Flat': {
            'ChargeValue': 10.0
        }
    }
)
custom_line_item_arn = response['arn']
```

**5. Verify the custom line item creation**

```python
response = client.get_custom_line_item(arn=custom_line_item_arn)
```

**6. List all custom line items**

```python
response = client.list_custom_line_items()
```

## Clean up

**Delete the custom line item**

```python
client.delete_custom_line_item(arn=custom_line_item_arn)
```

## Next steps

- Explore other aws billingconductor apis
- Integrate this script into your aws workflows