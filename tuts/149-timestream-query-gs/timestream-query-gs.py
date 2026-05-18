import boto3
import json
import time

client = boto3.client('timestream-query', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
scheduled_query_name = f"scheduled-query-{suffix}"
scheduled_query_arn = None
tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value': 'timestream-query-gs'}
]

try:
    query_string = "SELECT * FROM your_table WHERE time > ago(5m)"
    schedule_configuration = {
        'ScheduleExpression': 'cron(0/5 * * *? *)'
    }
    notification_configuration = {
        'SnsConfiguration': {
            'TopicArn': 'arn:aws:sns:us-east-1:123456789012:your-sns-topic'
        }
    }

    if 'Tags' in client.create_scheduled_query.__code__.co_varnames:
        response = client.create_scheduled_query(
            Name=scheduled_query_name,
            QueryString=query_string,
            ScheduleConfiguration=schedule_configuration,
            NotificationConfiguration=notification_configuration,
            Tags=tags
        )
    else:
        response = client.create_scheduled_query(
            Name=scheduled_query_name,
            QueryString=query_string,
            ScheduleConfiguration=schedule_configuration,
            NotificationConfiguration=notification_configuration
        )
        client.tag_resource(ResourceARN=response['ScheduledQueryArn'], Tags=tags)
    
    scheduled_query_arn = response['ScheduledQueryArn']
    print(f"Created Scheduled Query: {scheduled_query_arn}")

    # Verify Scheduled Query
    response = client.describe_scheduled_query(ScheduledQueryArn=scheduled_query_arn)
    print(f"Described Scheduled Query: {json.dumps(response, indent=2)}")

    # List Scheduled Queries
    response = client.list_scheduled_queries()
    print(f"Listed Scheduled Queries: {json.dumps(response, indent=2)}")

    # Get Account Settings
    response = client.describe_account_settings()
    print(f"Described Account Settings: {json.dumps(response, indent=2)}")

    # Get Endpoints
    response = client.describe_endpoints()
    print(f"Described Endpoints: {json.dumps(response, indent=2)}")

    # List Tags for Resource
    response = client.list_tags_for_resource(ResourceARN=scheduled_query_arn)
    print(f"Listed Tags for Resource: {json.dumps(response, indent=2)}")

    # Clean up
    response = client.delete_scheduled_query(ScheduledQueryArn=scheduled_query_arn)
    print(f"Deleted Scheduled Query: {scheduled_query_arn}")

    print("PASS")

except Exception as e:
    print(f"An error occurred: {e}")