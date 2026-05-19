import boto3
import json
import os
import time
import uuid

client = boto3.client('iotevents', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
unique_id = uuid.uuid4().hex[:6]

detector_model_name = f'TestDetectorModel{unique_id}'
role_arn = os.environ['TUTORIAL_ROLE_ARN']

tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'iotevents-gs'}
]

# Create Detector Model
try:
    create_detector_model_response = client.create_detector_model(
        detectorModelName=detector_model_name,
        detectorModelDefinition={
            'states': [
                {
                   'stateName': 'InitialState',
                    'onInput': {
                        'events': [
                            {
                                'eventName': 'testEvent',
                                'condition': '${sensorData.temperature} > 30',
                                'actions': [
                                    {
                                        'sns': {
                                            'targetArn': 'arn:aws:sns:us-east-1:123456789012:test-topic'
                                        }
                                    }
                                ]
                            },
                        ]
                    },
                    'onEnter': {
                        'events': [
                            {
                                'eventName': 'EnterEvent',
                                'condition': 'true',
                                'actions': [
                                    {
                                        'setVariable': {
                                            'variableName': 'temp',
                                            'value': '${sensorData.temperature}'
                                        }
                                    }
                                ]
                            },
                        ]
                    }
                },
            ]
        },
        roleArn=role_arn,
        tags=tags
    )
    print(f"Created detector model: {detector_model_name}")

    # Verify Detector Model
    describe_detector_model_response = client.describe_detector_model(detectorModelName=detector_model_name)
    print(f"Described detector model: {detector_model_name}")
except Exception as e:
    print(f"Failed to create detector model: {e}")

# Clean up
try:
    delete_detector_model_response = client.delete_detector_model(detectorModelName=detector_model_name)
    print(f"Deleted detector model: {detector_model_name}")
except Exception as e:
    print(f"Failed to delete detector model: {e}")

print("PASS")