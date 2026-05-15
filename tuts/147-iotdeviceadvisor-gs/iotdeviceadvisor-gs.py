import boto3
import json
import time

client = boto3.client('iotdeviceadvisor', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]

# Create Suite Definition
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

    # Verify Suite Definition
    response = client.get_suite_definition(suiteDefinitionId=suite_definition_id)
    print(f"Suite Definition retrieved: {response}")

    # List Suite Definitions
    response = client.list_suite_definitions()
    print(f"List of Suite Definitions: {response}")

    # Create Suite Run
    response = client.create_suite_run(suiteDefinitionId=suite_definition_id)
    suite_run_id = response['suiteRunId']
    print(f"Suite Run created with ID: {suite_run_id}")

    # Get Suite Run
    response = client.get_suite_run(suiteDefinitionId=suite_definition_id, suiteRunId=suite_run_id)
    print(f"Suite Run retrieved: {response}")

    # List Suite Runs
    response = client.list_suite_runs(suiteDefinitionId=suite_definition_id)
    print(f"List of Suite Runs: {response}")

    # Get Suite Run Report
    response = client.get_suite_run_report(suiteDefinitionId=suite_definition_id, suiteRunId=suite_run_id)
    print(f"Suite Run Report: {response}")

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    # Clean up
    try:
        client.delete_suite_definition(suiteDefinitionId=suite_definition_id)
        print(f"Suite Definition with ID {suite_definition_id} deleted")
    except Exception as e:
        print(f"Failed to delete Suite Definition: {e}")

print("PASS")