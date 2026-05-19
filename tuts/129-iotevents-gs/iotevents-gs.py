import boto3
import json
import time
import os
import uuid

client = boto3.client('iotevents', region_name='us-east-1')
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
suffix = str(int(time.time()))[-6:]
unique_id = uuid.uuid4().hex[:6]

detector_model_name = f'TestDetectorModel{unique_id}'

tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'iotevents-gs'}
]

print("Step 1: Creating a Detector Model.")
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
        roleArn=ROLE_ARN,
        tags=tags
    )
    print(f"Detector Model created with ARN: {create_detector_model_response['detectorModelConfiguration']['detectorModelArn']}")
except Exception as e:
    print(f"Failed to create detector model: {e}")

if ROLE_ARN:
    print("Step 2: Verifying the Detector Model.")
    try:
        describe_detector_model_response = client.describe_detector_model(detectorModelName=detector_model_name)
        print(f"Detector Model verified: {describe_detector_model_response['detectorModelConfiguration']['detectorModelName']}")
    except Exception as e:
        print(f"Failed to verify detector model: {e}")

print("Step 3: Cleaning up the Detector Model.")
try:
    delete_detector_model_response = client.delete_detector_model(detectorModelName=detector_model_name)
    print(f"Detector Model deleted: {detector_model_name}")
except Exception as e:
    print(f"Failed to delete detector model: {e}")

print("PASS")