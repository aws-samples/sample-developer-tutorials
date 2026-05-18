import boto3
import time
import random

suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
client = boto3.client('sagemaker-a2i-runtime', region_name='us-east-1')

try:
    print("Listing Human Loops:")
    response = client.list_human_loops(CreationSortOrder='Descending', MaxResults=10)
    print(response)

    if response['HumanLoopSummaries']:
        human_loop_name = response['HumanLoopSummaries'][0]['HumanLoopName']
        print("Describing Human Loop:")
        response = client.describe_human_loop(HumanLoopName=human_loop_name)
        print(response)
    else:
        print("No existing Human Loops found. Creating a new one.")
        response = client.start_human_loop(
            HumanLoopName=f'test-human-loop-{suffix}',
            HumanLoopInput={
                'InputContent': '{"task":"example"}',
                'DataSources': {
                    'S3DataSource': {
                        'S3Uri':'s3://example-bucket/example-key'
                    }
                }
            },
            HumanLoopConfig={
                'WorkteamArn': 'arn:aws:sagemaker:us-east-1:123456789012:workteam/private-123456789012',
                'HumanTaskUiArn': 'arn:aws:sagemaker:us-east-1:123456789012:human-task-ui/123456789012',
                'TaskCount': 1,
                'TaskDescription': 'Example task',
                'TaskTitle': 'Example Task Title'
            },
            Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'sagemaker-a2i-runtime-gs'}]
        )
        human_loop_name = response['HumanLoopName']
        time.sleep(10)  # Wait for the HumanLoop to start
        print("Describing newly created Human Loop:")
        response = client.describe_human_loop(HumanLoopName=human_loop_name)
        print(response)

        print("Stopping Human Loop:")
        client.stop_human_loop(HumanLoopName=human_loop_name)
        time.sleep(10)  # Wait for the HumanLoop to stop
        print("Deleting Human Loop:")
        client.delete_human_loop(HumanLoopName=human_loop_name)

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")