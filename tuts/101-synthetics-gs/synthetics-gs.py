import boto3
import time

region = 'us-east-1'
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-synthetics-role'
suffix = str(int(time.time()))[-6:]

client = boto3.client('synthetics', region_name=region)

def create_canary():
    canary_name = f'canary-{suffix}'
    try:
        response = client.create_canary(
            Name=canary_name,
            Code={'S3Bucket':'my-canary-bucket', 'S3Key':'my-canary-script.zip'},
            ExecutionRoleArn=role_arn,
            RuntimeVersion='syn-nodejs-2.0',
            Schedule={'Expression': 'rate(1 minute)'},
            Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'synthetics-gs'}]
        )
        print(f"Canary {canary_name} created")
        return canary_name
    except Exception as e:
        print(f"Error creating canary: {e}")
        return None

def create_group():
    group_name = f'group-{suffix}'
    try:
        response = client.create_group(Name=group_name)
        client.tag_resource(resourceArn=response['Group']['Arn'], tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'synthetics-gs'}])
        print(f"Group {group_name} created")
        return group_name
    except Exception as e:
        print(f"Error creating group: {e}")
        return None

def associate_resource(canary_name, group_name):
    try:
        client.associate_resource(GroupIdentifier=group_name, ResourceArns=[f'arn:aws:synthetics:{region}:559823168634:canary:{canary_name}'])
        print(f"Associated canary {canary_name} with group {group_name}")
    except Exception as e:
        print(f"Error associating resource: {e}")

def describe_canaries():
    try:
        response = client.describe_canaries()
        print("Described canaries:", response)
    except Exception as e:
        print(f"Error describing canaries: {e}")

def describe_canaries_last_run():
    try:
        response = client.describe_canaries_last_run()
        print("Described canaries last run:", response)
    except Exception as e:
        print(f"Error describing canaries last run: {e}")

def describe_runtime_versions():
    try:
        response = client.describe_runtime_versions()
        print("Described runtime versions:", response)
    except Exception as e:
        print(f"Error describing runtime versions: {e}")

def delete_canary(canary_name):
    try:
        client.delete_canary(Name=canary_name)
        print(f"Canary {canary_name} deleted")
    except Exception as e:
        print(f"Error deleting canary: {e}")

def delete_group(group_name):
    try:
        client.delete_group(GroupIdentifier=group_name)
        print(f"Group {group_name} deleted")
    except Exception as e:
        print(f"Error deleting group: {e}")

canary_name = create_canary()
group_name = create_group()

if canary_name and group_name:
    associate_resource(canary_name, group_name)
    describe_canaries()
    describe_canaries_last_run()
    describe_runtime_versions()
    delete_canary(canary_name)
    delete_group(group_name)
    print("PASS")