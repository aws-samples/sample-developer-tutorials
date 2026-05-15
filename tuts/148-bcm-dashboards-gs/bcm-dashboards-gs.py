import boto3
import time

client = boto3.client('ce', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
dashboard_name = f"dashboard-{suffix}"

# Create Cost Category
try:
    response = client.create_cost_category_definition(
        CostCategoryName=dashboard_name,
        RuleVersion='CostCategoryExpression.v1',
        Rules=[
            {
                'Type': 'REGULAR',
                'Value': 'Sample Value',
                'Rule': {
                    'And': [
                        {
                            'Or': [
                                {
                                    'Dimension': {
                                        'Key': 'SERVICE',
                                        'Values': [
                                            'Amazon S3',
                                        ]
                                    }
                                },
                            ]
                        },
                        {
                            'Not': {
                                'Dimension': {
                                    'Key': 'USAGE_TYPE',
                                    'Values': [
                                        'DataTransfer-Out-Bytes',
                                    ]
                                }
                            }
                        },
                    ]
                }
            },
        ],
        SplitChargeRules=[
            {
                'Type': 'ALLOCATE_FIXED',
                'Value': '100',
                'Source': 'UNCATEGORIZED',
                'Targets': [
                    'SampleTarget',
                ]
            },
        ]
    )
    cost_category_arn = response['CostCategoryArn']
    print(f"Cost Category created with ARN: {cost_category_arn}")

    # Verify Cost Category Creation
    get_response = client.describe_cost_category_definition(CostCategoryArn=cost_category_arn)
    print(f"Retrieved cost category: {get_response['CostCategoryArn']}")

    # List Cost Categories
    list_response = client.list_cost_categories()
    print(f"Listed cost categories: {list_response['CostCategories']}")

    # Clean Up
    client.delete_cost_category_definition(CostCategoryArn=cost_category_arn)
    print(f"Deleted cost category with ARN: {cost_category_arn}")

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")
    print("FAIL")