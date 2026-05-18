# Amazon SageMaker A2I Runtime Tutorial

## Prerequisites

- An aws account.
- Python installed with boto3 library.
- Aws credentials configured.

## Steps

**1. List human loops**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client('sagemaker-a2i-runtime', region_name='us-east-1'); print("Listing Human Loops:"); response = client.list_human_loops(CreationSortOrder='Descending', MaxResults=10); print(response)'
```

**2. Describe or create a human loop**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client('sagemaker-a2i-runtime', region_name='us-east-1'); try: print("Describing Human Loop:"); response = client.describe_human_loop(HumanLoopName="test-human-loop-' + suffix + '"); print(response); except: print("No existing Human Loops found. Creating a new one."); response = client.start_human_loop(HumanLoopName="test-human-loop-' + suffix + '", HumanLoopInput={"InputContent": '{"task":"example"}', "DataSources": {"S3DataSource": {"S3Uri":"s3://example-bucket/example-key"}}}, HumanLoopConfig={"WorkteamArn": "arn:aws:sagemaker:us-east-1:123456789012:workteam/private-123456789012", "HumanTaskUiArn": "arn:aws:sagemaker:us-east-1:123456789012:human-task-ui/123456789012", "TaskCount": 1, "TaskDescription": "Example task", "TaskTitle": "Example Task Title"}, Tags=[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"sagemaker-a2i-runtime-gs"}]); time.sleep(10); print("Describing newly created Human Loop:"); response = client.describe_human_loop(HumanLoopName="test-human-loop-' + suffix + '"); print(response); print("PASS")'
```

## Clean up

**1. Stop the human loop**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client('sagemaker-a2i-runtime', region_name='us-east-1'); print("Stopping Human Loop:"); client.stop_human_loop(HumanLoopName="test-human-loop-' + suffix + '"); time.sleep(10)'
```

**2. Delete the human loop**

```bash
$ python -c 'import boto3; import time; import random; suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100)); client = boto3.client('sagemaker-a2i-runtime', region_name='us-east-1'); print("Deleting Human Loop:"); client.delete_human_loop(HumanLoopName="test-human-loop-' + suffix + '")'
```

## Next steps

- Explore more about [amazon sagemaker](https://aws.amazon.com/sagemaker/).
- Learn about [aws a2i](https://aws.amazon.com/augmented-ai/).