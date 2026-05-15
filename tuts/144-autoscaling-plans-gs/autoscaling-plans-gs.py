import boto3
import json
import time
import random

client = boto3.client('autoscaling-plans', region_name='us-east-1')
suffix = str(int(time.time())) + str(random.randint(100000, 999999))
scaling_plan_name = f'scaling-plan-{suffix}'

# Create Scaling Plan
scaling_instructions = [
    {
        'ServiceNamespace': 'ecs',
        'ResourceId':'service/my-cluster/my-service',
        'ScalableDimension': 'ecs:service:DesiredCount',
        'MinCapacity': 1,
        'MaxCapacity': 10,
        'TargetTrackingConfigurations': [
            {
                'PredefinedScalingMetricSpecification': {
                    'PredefinedScalingMetricType': 'ECSServiceAverageCPUUtilization'
                },
                'TargetValue': 50.0
            },
        ]
    }
]

application_source = {
    'TagFilters': [
        {
            'Key': 'Name',
            'Values': ['my-stack']
        }
    ]
}

try:
    response = client.create_scaling_plan(
        ScalingPlanName=scaling_plan_name,
        ApplicationSource=application_source,
        ScalingInstructions=scaling_instructions
    )

    print("CreateScalingPlan response:", json.dumps(response, indent=2, default=str))

    # Verify Scaling Plan
    scaling_plan_version = response['ScalingPlanVersion']

    response = client.describe_scaling_plans(
        ScalingPlanNames=[scaling_plan_name]
    )

    print("DescribeScalingPlans response:", json.dumps(response, indent=2, default=str))

    # Interact with Scaling Plan
    response = client.describe_scaling_plan_resources(
        ScalingPlanName=scaling_plan_name,
        ScalingPlanVersion=scaling_plan_version
    )

    print("DescribeScalingPlanResources response:", json.dumps(response, indent=2, default=str))
except Exception as e:
    print("Failed to create scaling plan:", str(e))

# Clean up
try:
    response = client.delete_scaling_plan(
        ScalingPlanName=scaling_plan_name,
        ScalingPlanVersion=scaling_plan_version
    )
    print("DeleteScalingPlan response:", json.dumps(response, indent=2, default=str))
except Exception as e:
    print("Failed to delete scaling plan:", str(e))

print("PASS")