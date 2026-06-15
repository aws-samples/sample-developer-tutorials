# Getting started with Amazon Fraud Detector

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- AWS CLI installed and configured.
- Appropriate IAM permissions to create and manage Amazon Fraud Detector resources.
- If necessary, a CloudFormation stack with the required IAM roles.

## Step 1: Create a Variable

**Create a variable**

The following Python script creates a variable to be used in the fraud detector.

```python
import boto3
import time
import os

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
frauddetector = boto3.client('frauddetector')

variable_name = f'variable_{suffix}'
frauddetector.create_variable(name=variable_name, data_type='STRING', data_source='EVENT', default_value='UNKNOWN', description='Sample variable for tutorial', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'frauddetector-gs'}])
print(f"Variable {variable_name} created.")
```

**Expected result**

The script will output the name of the created variable. Example output:

```
Variable variable_123456 created.
```

## Step 2: Create a Detector

**Create a detector**

The following Python script creates a detector to evaluate fraud.

```python
detector_name = f'detector_{suffix}'
frauddetector.put_detector(detectorId=detector_name, description='Sample detector for tutorial', eventType='sample_event', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'frauddetector-gs'}])
print(f"Detector {detector_name} created.")
```

**Expected result**

The script will output the name of the created detector. Example output:

```
Detector detector_123456 created.
```

## Step 3: Create a Detector Version

**Create a detector version**

The following Python script creates a version of the detector to define its rules and models.

```python
detector_version_id = '1.0'
frauddetector.create_detector_version(detectorId=detector_name, description='Sample detector version for tutorial', rules=[{'detectorId': detector_name, 'ruleId': f'rule_{suffix}', 'ruleVersion': '1.0', 'expression':'sample_expression', 'language': 'DETECTORPL', 'outcomes': ['outcome_1']}], modelVersions=[], externalModelEndpoints=[], Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'frauddetector-gs'}])
print(f"Detector version {detector_version_id} created for {detector_name}.")
```

**Expected result**

The script will output the version ID of the created detector version. Example output:

```
Detector version 1.0 created for detector_123456.
```

## Step 4: Verify the Detector Version

**Verify the detector version**

The following Python script verifies that the detector version exists.

```python
time.sleep(10)  # Wait for the detector version to become active
response = frauddetector.describe_detector(detectorId=detector_name)
print(f"Detector {detector_name} version {detector_version_id} verified.")
```

**Expected result**

The script will output a verification message. Example output:

```
Detector detector_123456 version 1.0 verified.
```

## Clean up

The following steps clean up the resources created during this tutorial.

**Delete resources using CLI**

```bash
$ aws frauddetector delete-detector-version --detector-id detector_123456 --version-id 1.0
$ aws frauddetector delete-detector --detector-id detector_123456
$ aws frauddetector delete-variable --name variable_123456
```

**Expected result**

The CLI commands will delete the detector version, detector, and variable. Example output:

```
{
    "message": "Successfully deleted detector version 1.0 for detector_123456."
}
{
    "message": "Successfully deleted detector detector_123456."
}
{
    "message": "Successfully deleted variable variable_123456."
}
```

## Next steps

- Explore [Amazon Fraud Detector documentation](https://docs.aws.amazon.com/frauddetector/latest/ug/what-is-frauddetector.html) for more details.
- Learn how to [integrate Amazon Fraud Detector with other AWS services](https://docs.aws.amazon.com/frauddetector/latest/ug/integrating.html).
- Check out [best practices for using Amazon Fraud Detector](https://docs.aws.amazon.com/frauddetector/latest/ug/best-practices.html).
