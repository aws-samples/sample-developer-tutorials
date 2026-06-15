import boto3
import json
import time
import os
import uuid

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('billingconductor', region_name='us-east-1')

suffix = str(int(time.time()))[-6:]
client_token = uuid.uuid4().hex[:8]
tags = {'project': 'doc-smith', 'tutorial': 'billingconductor-gs'}

print("Creating a Pricing Rule...")
response = client.create_pricing_rule(
    ClientToken=client_token,
    Name=f"TestPricingRule{suffix}",
    Description="Test Pricing Rule Description",
    Scope="GLOBAL",
    Type="MARKUP",
    ModifierPercentage=10.0,
    Tags=tags
)
pricing_rule_arn = response['Arn']
print(f"Pricing Rule created with ARN: {pricing_rule_arn}")

print("Verifying Pricing Rule...")
response = client.list_pricing_rules(
    Filters={
        'Arns': [pricing_rule_arn]
    }
)
if response['PricingRules'] and response['PricingRules'][0]['Name'] == f"TestPricingRule{suffix}":
    print(f"Pricing Rule verified: {pricing_rule_arn}")
else:
    print("Pricing Rule verification failed")
    exit(1)

print("Creating a Pricing Plan...")
pricing_plan_response = client.create_pricing_plan(
    Name=f'tutorial-pricing-plan-{suffix}',
    PricingRuleArns=[pricing_rule_arn],
    Tags=tags
)
pricing_plan_arn = pricing_plan_response['Arn']
print(f"Pricing Plan created with ARN: {pricing_plan_arn}")

if ROLE_ARN:
    print("Creating a Billing Group...")
    billing_group_response = client.create_billing_group(
        Name=f'tutorial-billing-group-{suffix}',
        AccountGrouping={'LinkedAccountIds': []},
        ComputationPreference={'PricingPlanArn': pricing_plan_arn},
        Tags=tags
    )
    billing_group_arn = billing_group_response['Arn']
    print(f"Billing Group created with ARN: {billing_group_arn}")

    print("Creating a Custom Line Item...")
    custom_line_item_response = client.create_custom_line_item(
        Name=f'tutorial-custom-line-item-{suffix}',
        Description='Tutorial Custom Line Item',
        BillingGroupArn=billing_group_arn,
        ChargeDetails={
            'Flat': {
                'ChargeValue': 10.0
            },
            'Type': 'CREDIT'
        },
        Tags=tags
    )
    custom_line_item_arn = custom_line_item_response['Arn']
    print(f"Custom Line Item created with ARN: {custom_line_item_arn}")
else:
    print("ROLE_ARN not set, skipping Billing Group and Custom Line Item creation steps.")

time.sleep(10)  # Wait for resources to be available

print("Cleaning up resources...")

if ROLE_ARN:
    client.delete_custom_line_item(Arn=custom_line_item_arn)
    print(f"Custom Line Item with ARN {custom_line_item_arn} deleted.")
    client.delete_billing_group(Arn=billing_group_arn)
    print(f"Billing Group with ARN {billing_group_arn} deleted.")

client.delete_pricing_plan(Arn=pricing_plan_arn)
print(f"Pricing Plan with ARN {pricing_plan_arn} deleted.")
client.delete_pricing_rule(Arn=pricing_rule_arn)
print(f"Pricing Rule with ARN {pricing_rule_arn} deleted.")