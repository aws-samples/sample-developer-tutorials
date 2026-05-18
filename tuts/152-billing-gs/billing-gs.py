import boto3
import json
import time

# Initialize the Boto3 client for AWS Billing
client = boto3.client('billingconductor', region_name='us-east-1')

# Generate a unique suffix for resource names
suffix = str(int(time.time()))[-6:]
resource_name = f"billing-view-{suffix}"

# Define the source views (example, replace with actual source views)
source_views = [
    "arn:aws:billingconductor::123456789012:billingview/source-view-1",
    "arn:aws:billingconductor::123456789012:billingview/source-view-2"
]

try:
    # Create a billing view
    response = client.create_custom_line_item(
        name=resource_name,
        description="Test custom line item",
        billingPeriodRange={
            'ExclusiveEndBillingPeriod': "2024-05",
            'InclusiveStartBillingPeriod': "2024-03"
        },
        billingGroupArn="arn:aws:billingconductor::123456789012:billinggroup/test-billing-group",
        customLineItemChargeDetails={
            'Flat': {
                'ChargeValue': 10.0
            }
        }
    )
    custom_line_item_arn = response['arn']

    # Add tags to the created resource
    client.tag_resource(
        ResourceArn=custom_line_item_arn,
        Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'billing-gs'}]
    )

    print(f"Created custom line item with ARN: {custom_line_item_arn}")

    # Verify the custom line item creation
    response = client.get_custom_line_item(arn=custom_line_item_arn)
    print(f"Retrieved custom line item: {json.dumps(response, indent=2)}")

    # List all custom line items
    response = client.list_custom_line_items()
    print(f"Listed custom line items: {json.dumps(response, indent=2)}")

    # Clean up by deleting the custom line item
    client.delete_custom_line_item(arn=custom_line_item_arn)
    print(f"Deleted custom line item with ARN: {custom_line_item_arn}")

    print("PASS")
except Exception as e:
    print(f"An error occurred: {e}")
    print("FAIL")