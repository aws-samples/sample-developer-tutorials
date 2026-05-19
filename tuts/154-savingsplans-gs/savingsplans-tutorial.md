# Tutorial: Getting Started with AWS Savings Plans

## Prerequisites

- An AWS account.
- AWS CLI installed and configured.
- Python installed with `boto3` library.

## Steps

### **1. Initialize the Savings Plans client**

```python
import boto3

client = boto3.client('savingsplans', region_name='us-east-1')
```

### **2. Generate a unique suffix for resource names**

```python
import time
import uuid

suffix = str(int(time.time()))[-6:]
unique_id = f"doc-smith-{suffix}"
```

### **3. Define tags for the resources**

```python
tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value':'savingsplans-gs'}
]
```

### **4. Describe Savings Plans Offerings**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); response = client.describe_savings_plans_offerings(); print(response)'
```

### **5. Select the first offering for creating a Savings Plan**

```python
if offerings:
    savings_plan_offering_id = offerings[0]['SavingsPlanOfferingId']
    print("Selected Savings Plan Offering ID:", savings_plan_offering_id)
else:
    print("No Savings Plan Offerings found.")
    exit()
```

### **6. Create a Savings Plan**

```bash
$ python -c 'import boto3; import uuid; client = boto3.client("savingsplans"); create_response = client.create_savings_plan(savingsPlanOfferingId="offering_id", commitment="2000", clientToken=str(uuid.uuid4()), tags=tags); print(create_response)'
```

### **7. Describe Savings Plans**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); describe_response = client.describe_savings_plans(savingsPlanIds=["savings_plan_id"]); print(describe_response)'
```

### **8. Describe Savings Plan Rates**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); rates_response = client.describe_savings_plan_rates(savingsPlanId="savings_plan_id"); print(rates_response)'
```

### **9. Describe Savings Plans Offering Rates**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); offering_rates_response = client.describe_savings_plans_offering_rates(savingsPlanOfferingIds=["offering_id"]); print(offering_rates_response)'
```

### **10. List Tags for Resource**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); list_tags_response = client.list_tags_for_resource(resourceArn="arn:aws:savingsplans:us-east-1:123456789012:savingsplan/savings_plan_id"); print(list_tags_response)'
```

## Clean up

### **1. Delete the Savings Plan**

```bash
$ python -c 'import boto3; client = boto3.client("savingsplans"); delete_response = client.delete_queued_savings_plan(savingsPlanId="savings_plan_id"); print(delete_response)'
```

## Next steps

- Explore more AWS Savings Plans features.
- Integrate Savings Plans with your billing and cost management dashboard.