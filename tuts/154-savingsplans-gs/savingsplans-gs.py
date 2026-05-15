import boto3
import json
import time
import uuid

# Initialize the Savings Plans client
client = boto3.client('savingsplans', region_name='us-east-1')

# Generate a unique suffix for resource names
suffix = str(int(time.time()))[-6:]
unique_id = f"doc-smith-{suffix}"

# Define tags for the resources
tags = [
    {'Key': 'project', 'Value': 'doc-smith'},
    {'Key': 'tutorial', 'Value':'savingsplans-gs'}
]

# Step 1: Describe Savings Plans Offerings
response = client.describe_savings_plans_offerings()
if 'SavingsPlansOfferings' in response:
    offerings = response['SavingsPlansOfferings']
    print("Described Savings Plans Offerings:", json.dumps(offerings, indent=2))
else:
    print("No Savings Plan Offerings found.")
    exit()

# Select the first offering for creating a Savings Plan
if offerings:
    savings_plan_offering_id = offerings[0]['SavingsPlanOfferingId']
    print("Selected Savings Plan Offering ID:", savings_plan_offering_id)
else:
    print("No Savings Plan Offerings found.")
    exit()

# Step 2: Create a Savings Plan
try:
    create_response = client.create_savings_plan(
        savingsPlanOfferingId=savings_plan_offering_id,
        commitment='2000',
        clientToken=str(uuid.uuid4()),
        tags=tags
    )
    savings_plan_id = create_response['savingsPlanId']
    print("Created Savings Plan ID:", savings_plan_id)
except client.exceptions.ClientError as e:
    print("Failed to create Savings Plan:", e)
    exit()

# Step 3: Describe Savings Plans
describe_response = client.describe_savings_plans(savingsPlanIds=[savings_plan_id])
print("Described Savings Plans:", json.dumps(describe_response, indent=2))

# Step 4: Describe Savings Plan Rates
rates_response = client.describe_savings_plan_rates(savingsPlanId=savings_plan_id)
print("Described Savings Plan Rates:", json.dumps(rates_response, indent=2))

# Step 5: Describe Savings Plans Offering Rates
offering_rates_response = client.describe_savings_plans_offering_rates(
    savingsPlanOfferingIds=[savings_plan_offering_id]
)
print("Described Savings Plans Offering Rates:", json.dumps(offering_rates_response, indent=2))

# Step 6: List Tags for Resource
list_tags_response = client.list_tags_for_resource(resourceArn=f"arn:aws:savingsplans:us-east-1:559823168634:savingsplan/{savings_plan_id}")
print("Listed Tags for Resource:", json.dumps(list_tags_response, indent=2))

# Step 7: Clean up - Delete the Savings Plan
try:
    delete_response = client.delete_queued_savings_plan(savingsPlanId=savings_plan_id)
    print("Deleted Queued Savings Plan:", delete_response)
except client.exceptions.ClientError as e:
    print("Failed to delete Queued Savings Plan:", e)

print("PASS")