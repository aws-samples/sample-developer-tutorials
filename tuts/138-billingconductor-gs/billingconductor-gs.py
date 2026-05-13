import boto3
import json
import time
import uuid

client = boto3.client('billingconductor', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
client_token = uuid.uuid4().hex[:8]

# Create Pricing Rule
pricing_rule_name = f"TestPricingRule{suffix}"
pricing_rule_description = "Test Pricing Rule Description"
pricing_rule_scope = "GLOBAL"
pricing_rule_type = "MARKUP"
modifier_percentage = 10.0

response = client.create_pricing_rule(
    ClientToken=client_token,
    Name=pricing_rule_name,
    Description=pricing_rule_description,
    Scope=pricing_rule_scope,
    Type=pricing_rule_type,
    ModifierPercentage=modifier_percentage
)

pricing_rule_arn = response['Arn']
print(f"Pricing Rule created: {pricing_rule_arn}")

# Verify Pricing Rule
response = client.list_pricing_rules(
    Filters={
        'Arns': [pricing_rule_arn]
    }
)

if response['PricingRules'] and response['PricingRules'][0]['Name'] == pricing_rule_name:
    print(f"Pricing Rule verified: {pricing_rule_name}")
else:
    print("Pricing Rule verification failed")
    exit(1)

# Interact with Pricing Rule (List Pricing Rules)
response = client.list_pricing_rules()
print("Listing Pricing Rules:")
print(json.dumps(response, indent=2))

# Clean up
client.delete_pricing_rule(
    Arn=pricing_rule_arn
)
print(f"Pricing Rule deleted: {pricing_rule_arn}")

print("PASS")