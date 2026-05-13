import boto3
import time

region = 'us-east-1'
suffix = str(int(time.time()))[-6:]
iam_role_arn = 'arn:aws:iam::559823168634:role/doc-babu-route53-role'

route53 = boto3.client('route53', region_name=region)

def create_hosted_zone():
    try:
        response = route53.create_hosted_zone(Name=f'example-{suffix}.com.', CallerReference=str(time.time()))
        hosted_zone_id = response['HostedZone']['Id']
        print(f"Created Hosted Zone: {hosted_zone_id}")
        return hosted_zone_id
    except Exception as e:
        print(f"Error creating hosted zone: {e}")
        raise

def create_health_check():
    try:
        response = route53.create_health_check(CallerReference=str(time.time()), HealthCheckConfig={
            'IPAddress': '192.0.2.44',
            'Port': 80,
            'Type': 'HTTP',
            'ResourcePath': '/',
            'FullyQualifiedDomainName': f'example-{suffix}.com.'
        })
        health_check_id = response['HealthCheck']['Id']
        print(f"Created Health Check: {health_check_id}")
        return health_check_id
    except Exception as e:
        print(f"Error creating health check: {e}")
        raise

def create_traffic_policy():
    try:
        response = route53.create_traffic_policy(Name=f'policy-{suffix}', Document="""{
            "Comment": "A sample traffic policy",
            "Rules": [
                {
                    "Name": "my_rule",
                    "Type": "A",
                    "ResourceRecordSets": [
                        {
                            "ResourceRecords": [
                                {
                                    "Value": "192.0.2.44"
                                }
                            ],
                            "TTL": 300,
                            "Type": "A"
                        }
                    ]
                }
            ]
        }""")
        traffic_policy_id = response['TrafficPolicy']['Id']
        print(f"Created Traffic Policy: {traffic_policy_id}")
        return traffic_policy_id
    except Exception as e:
        print(f"Error creating traffic policy: {e}")
        raise

def create_traffic_policy_instance(hosted_zone_id, traffic_policy_id):
    try:
        response = route53.create_traffic_policy_instance(HostedZoneId=hosted_zone_id, Name=f'instance-{suffix}.example.com.', TrafficPolicyId=traffic_policy_id, TTL=300)
        traffic_policy_instance_id = response['TrafficPolicyInstance']['Id']
        print(f"Created Traffic Policy Instance: {traffic_policy_instance_id}")
    except Exception as e:
        print(f"Error creating traffic policy instance: {e}")
        raise

def delete_resources(hosted_zone_id, health_check_id, traffic_policy_id, traffic_policy_instance_id):
    try:
        route53.delete_traffic_policy_instance(Id=traffic_policy_instance_id)
        print(f"Deleted Traffic Policy Instance: {traffic_policy_instance_id}")
    except Exception as e:
        print(f"Error deleting traffic policy instance: {e}")

    try:
        route53.delete_traffic_policy(Id=traffic_policy_id, Version=1)
        print(f"Deleted Traffic Policy: {traffic_policy_id}")
    except Exception as e:
        print(f"Error deleting traffic policy: {e}")

    try:
        route53.delete_health_check(HealthCheckId=health_check_id)
        print(f"Deleted Health Check: {health_check_id}")
    except Exception as e:
        print(f"Error deleting health check: {e}")

    try:
        route53.delete_hosted_zone(Id=hosted_zone_id)
        print(f"Deleted Hosted Zone: {hosted_zone_id}")
    except Exception as e:
        print(f"Error deleting hosted zone: {e}")

try:
    hosted_zone_id = create_hosted_zone()
    health_check_id = create_health_check()
    traffic_policy_id = create_traffic_policy()
    create_traffic_policy_instance(hosted_zone_id, traffic_policy_id)
    delete_resources(hosted_zone_id, health_check_id, traffic_policy_id, traffic_policy_instance_id)
    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")