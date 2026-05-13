import boto3
import time

region = 'us-east-1'
iam_role_arn = 'arn:aws:iam::559823168634:role/doc-babu-scheduler-role'
suffix = str(int(time.time()))[-6:]
scheduler = boto3.client('scheduler', region_name=region)

def create_schedule_group(name):
    try:
        response = scheduler.create_schedule_group(Name=name)
        print(f"Created Schedule Group: {name}")
        return response['ScheduleGroupArn']
    except Exception as e:
        print(f"Error creating schedule group: {e}")
        raise

def create_schedule(group_arn, name):
    try:
        response = scheduler.create_schedule(
            Name=name,
            ScheduleExpression='rate(5 minutes)',
            Target= {
                'Arn': iam_role_arn,
                'RoleArn': iam_role_arn
            },
            ScheduleExpressionTimezone='America/New_York',
            State='ENABLED',
            ScheduleGroupName=group_arn.split(':')[-1]
        )
        print(f"Created Schedule: {name}")
        return response['ScheduleArn']
    except Exception as e:
        print(f"Error creating schedule: {e}")
        raise

def delete_schedule(arn):
    try:
        scheduler.delete_schedule(Name=arn.split(':')[-1], ScheduleGroup=arn.split(':')[-2])
        print(f"Deleted Schedule: {arn}")
    except Exception as e:
        print(f"Error deleting schedule: {e}")
        raise

def delete_schedule_group(arn):
    try:
        scheduler.delete_schedule_group(Name=arn.split(':')[-1])
        print(f"Deleted Schedule Group: {arn}")
    except Exception as e:
        print(f"Error deleting schedule group: {e}")
        raise

try:
    group_name = f'group-{suffix}'
    schedule_name = f'schedule-{suffix}'

    group_arn = create_schedule_group(group_name)
    schedule_arn = create_schedule(group_arn, schedule_name)

    delete_schedule(schedule_arn)
    delete_schedule_group(group_arn)

    print("PASS")
except Exception as e:
    print(f"Script failed: {e}")