# Getting started with AWS Billing Conductor

This tutorial will guide you through the basics of using AWS Billing Conductor to create and manage custom pricing rules, plans, and billing groups.

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured.
- Necessary IAM permissions to use AWS Billing Conductor.
- Optionally, a CloudFormation stack if you need to set up IAM roles for advanced features.

## Step 1: Create a Pricing Rule

**Guidance:** A pricing rule defines the pricing for your services. In this step, we will create a global markup pricing rule.

```python
import boto3, json, time, os, sys

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
client = boto3.client('billingconductor')

suffix = str(int(time.time()))[-6:]
Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'billingconductor-gs'}]

print("Creating a Pricing Rule...")
pricing_rule_response = client.create_pricing_rule(
    Name=f'tutorial-pricing-rule-{suffix}',
    Scope='GLOBAL',
    Type='MARKUP',
    Tags=Tags
)
pricing_rule_arn = pricing_rule_response['Arn']
print(f"Pricing Rule created with ARN: {pricing_rule_arn}")
```

**Expected Output:**
```
Creating a Pricing Rule...
Pricing Rule created with ARN: arn:aws:billingconductor:us-east-1:123456789012:pricingrule/tutorial-pricing-rule-123456
```

## Step 2: Create a Pricing Plan

**Guidance:** A pricing plan is a collection of pricing rules. In this step, we will create a pricing plan that includes the pricing rule created in the previous step.

```python
print("Creating a Pricing Plan...")
pricing_plan_response = client.create_pricing_plan(
    Name=f'tutorial-pricing-plan-{suffix}',
    PricingRuleArns=[pricing_rule_arn],
    Tags=Tags
)
pricing_plan_arn = pricing_plan_response['Arn']
print(f"Pricing Plan created with ARN: {pricing_plan_arn}")
```

**Expected Output:**
```
Creating a Pricing Plan...
Pricing Plan created with ARN: arn:aws:billingconductor:us-east-1:123456789012:pricingplan/tutorial-pricing-plan-123456
```

## Step 3: Create a Billing Group (Optional)

**Guidance:** A billing group allows you to group accounts together and apply a pricing plan to them. This step is optional and requires an IAM role with necessary permissions.

```python
if ROLE_ARN:
    print("Creating a Billing Group...")
    billing_group_response = client.create_billing_group(
        Name=f'tutorial-billing-group-{suffix}',
        AccountGrouping={'LinkedAccountIds': []},
        ComputationPreference={'PricingPlanArn': pricing_plan_arn},
        Tags=Tags
    )
    billing_group_arn = billing_group_response['Arn']
    print(f"Billing Group created with ARN: {billing_group_arn}")
else:
    print("ROLE_ARN not set, skipping Billing Group creation step.")
```

**Expected Output:**
```
Creating a Billing Group...
Billing Group created with ARN: arn:aws:billingconductor:us-east-1:123456789012:billinggroup/tutorial-billing-group-123456
```

## Step 4: Create a Custom Line Item (Optional)

**Guidance:** A custom line item allows you to add a fixed charge or credit to a billing group. This step is optional and requires an IAM role with necessary permissions.

```python
if ROLE_ARN:
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
        Tags=Tags
    )
    custom_line_item_arn = custom_line_item_response['Arn']
    print(f"Custom Line Item created with ARN: {custom_line_item_arn}")
else:
    print("ROLE_ARN not set, skipping Custom Line Item creation step.")
```

**Expected Output:**
```
Creating a Custom Line Item...
Custom Line Item created with ARN: arn:aws:billingconductor:us-east-1:123456789012:customlineitem/tutorial-custom-line-item-123456
```

## Clean up

**Guidance:** To avoid unnecessary charges, clean up the resources you created.

```python
print("Cleaning up resources...")

if ROLE_ARN:
    client.delete_custom_line_item(Arn=custom_line_item_arn)
    print(f"Custom Line Item with ARN {custom_line_item_arn} deleted.")
    client.delete_billing_group(Arn=billing_group_arn)
    print(f"Billing Group with ARN {billing_group_arn} deleted.")
```

**Expected Output:**
```
Cleaning up resources...
Custom Line Item with ARN arn:aws:billingconductor:us-east-1:123456789012:customlineitem/tutorial-custom-line-item-123456 deleted.
Billing Group with ARN arn:aws:billingconductor:us-east-1:123456789012:billinggroup/tutorial-billing-group-123456 deleted.
```

## Next steps

- Explore more complex pricing rules and plans.
- Associate more accounts with your billing groups.
- Monitor your costs and usage with AWS Cost Explorer.
