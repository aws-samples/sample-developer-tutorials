# Aws Iot Device Advisor Tutorial

## Prerequisites

- Aws account
- Aws cli configured with appropriate permissions
- Python installed
- Boto3 python library installed

## Steps

**1. Install boto3**

```bash
$ pip install boto3
```

**2. Create suite definition**

```python
import boto3
import json
import time

client = boto3.client('iotdeviceadvisor', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]

suite_definition_configuration = {
   'suiteDefinitionName': f'TestSuite{suffix}',
   'devices': [
       {
           'thingArn': 'arn:aws:iot:us-east-1:123456789012:thing/MyTestThing',
           'certificateArn': 'arn:aws:iot:us-east-1:123456789012:cert/12345678901234567890123456789012345'
       }
   ],
   'intendedForQualification': False,
   'isLongDurationTest': False,
   'protocol': 'Mqtt',
   'devicePermissionRoleArn': 'arn:aws:iam::559823168634:role/doc-babu-iotdeviceadvisor-role'
}

try:
    response = client.create_suite_definition(suiteDefinitionConfiguration=suite_definition_configuration)
    suite_definition_id = response['suiteDefinitionId']
    print(f"Suite Definition created with ID: {suite_definition_id}")
```

**3. Verify suite definition**

```python
    response = client.get_suite_definition(suiteDefinitionId=suite_definition_id)
    print(f"Suite Definition retrieved: {response}")
```

**4. List suite definitions**

```python
    response = client.list_suite_definitions()
    print(f"List of Suite Definitions: {response}")
```

**5. Create suite run**

```python
    response = client.create_suite_run(suiteDefinitionId=suite_definition_id)
    suite_run_id = response['suiteRunId']
    print(f"Suite Run created with ID: {suite_run_id}")
```

**6. Get suite run**

```python
    response = client.get_suite_run(suiteDefinitionId=suite_definition_id, suiteRunId=suite_run_id)
    print(f"Suite Run retrieved: {response}")
```

**7. List suite runs**

```python
    response = client.list_suite_runs(suiteDefinitionId=suite_definition_id)
    print(f"List of Suite Runs: {response}")
```

**8. Get suite run report**

```python
    response = client.get_suite_run_report(suiteDefinitionId=suite_definition_id, suiteRunId=suite_run_id)
    print(f"Suite Run Report: {response}")
```

## Clean up

**1. Delete suite definition**

```python
finally:
    try:
        client.delete_suite_definition(suiteDefinitionId=suite_definition_id)
        print(f"Suite Definition with ID {suite_definition_id} deleted")
    except Exception as e:
        print(f"Failed to delete Suite Definition: {e}")
```

## Next steps

- Explore aws iot device advisor documentation for more features
- Integrate with your iot solution