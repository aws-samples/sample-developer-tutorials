# Getting started with AWS IoT Events

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Appropriate IAM permissions to create and manage AWS IoT Events resources
- An IAM role with necessary permissions (if using the Python script)

If you need to create an IAM role, you can use the following CloudFormation stack:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  IoTEventsRole:
    Type: 'AWS::IAM::Role'
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: 'Allow'
            Principal:
              Service: 'iotevents.amazonaws.com'
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: 'IoTEventsPolicy'
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: 'Allow'
                Action:
                  - 'sns:Publish'
                Resource: '*'
```

## Step 1: Create an Input

**Create an Input resource**

This step creates an Input resource in AWS IoT Events. An Input represents the data stream that your detector model will process.

```bash
$ aws iotevents create-input \
  --input-name "tutorial-input-abc123" \
  --input-definition file://input-definition.json \
  --tags '{"Environment":"Tutorial","Project":"GettingStarted"}'
```

**Expected result**

You should see output similar to:

```json
{
    "inputConfiguration": {
        "inputName": "tutorial-input-abc123",
        "inputArn": "arn:aws:iotevents:us-west-2:123456789012:input/tutorial-input-abc123",
        "inputDescription": "Tutorial Input",
        "creationTime": "2023-04-01T12:00:00Z",
        "lastUpdateTime": "2023-04-01T12:00:00Z"
    }
}
```

## Step 2: Create a Detector Model

**Create a Detector Model resource**

This step creates a Detector Model resource in AWS IoT Events. A Detector Model defines the states, transitions, and actions for processing input data.

```bash
$ aws iotevents create-detector-model \
  --detector-model-name "tutorial-detector-abc123" \
  --detector-model-definition file://detector-model-definition.json \
  --role-arn "arn:aws:iam::123456789012:role/IoTEventsRole" \
  --tags '{"Environment":"Tutorial","Project":"GettingStarted"}'
```

**Expected result**

You should see output similar to:

```json
{
    "detectorModelConfiguration": {
        "detectorModelName": "tutorial-detector-abc123",
        "detectorModelArn": "arn:aws:iotevents:us-west-2:123456789012:detector-model/tutorial-detector-abc123",
        "detectorModelDescription": "",
        "detectorModelVersion": "1",
        "creationTime": "2023-04-01T12:00:00Z",
        "lastUpdateTime": "2023-04-01T12:00:00Z",
        "status": "ACTIVE",
        "key": ""
    }
}
```

## Step 3: Create an Alarm Model

**Create an Alarm Model resource**

This step creates an Alarm Model resource in AWS IoT Events. An Alarm Model defines the conditions under which an alarm is triggered and the actions to be taken.

```bash
$ aws iotevents create-alarm-model \
  --alarm-model-name "tutorial-alarm-abc123" \
  --alarm-model-description "Tutorial Alarm Model" \
  --role-arn "arn:aws:iam::123456789012:role/IoTEventsRole" \
  --severity 1 \
  --alarm-rule file://alarm-rule.json \
  --tags '{"Environment":"Tutorial","Project":"GettingStarted"}'
```

**Expected result**

You should see output similar to:

```json
{
    "alarmModelVersion": "1",
    "alarmModelArn": "arn:aws:iotevents:us-west-2:123456789012:alarm-model/tutorial-alarm-abc123",
    "status": "ACTIVE",
    "creationTime": "2023-04-01T12:00:00Z",
    "lastUpdateTime": "2023-04-01T12:00:00Z"
}
```

## Clean up

To avoid unnecessary charges, delete the resources you created:

```bash
$ aws iotevents delete-input --input-name "tutorial-input-abc123"
$ aws iotevents delete-detector-model --detector-model-name "tutorial-detector-abc123"
$ aws iotevents delete-alarm-model --alarm-model-name "tutorial-alarm-abc123"
```

## Next steps

- Explore [AWS IoT Events documentation](https://docs.aws.amazon.com/iotevents/) for more advanced features.
- Learn how to [integrate AWS IoT Events with other AWS services](https://docs.aws.amazon.com/iotevents/latest/developerguide/what-is-iotevents.html).
- Check out [AWS IoT Events pricing](https://aws.amazon.com/iot-events/pricing/) to understand the costs associated with using this service.
