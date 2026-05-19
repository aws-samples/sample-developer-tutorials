import boto3
import time

suffix = str(int(time.time()))[-6:]
rbin_client = boto3.client('resourcegroupstaggingapi', region_name='us-east-1')

def create_rule():
    try:
        print("Creating rule (dummy operation)")
        rule_arn = "arn:aws:someservice:us-east-1:123456789012:rule/example-rule-" + suffix
        tags = {'project': 'doc-smith', 'tutorial': 'rbin-gs'}
        rbin_client.tag_resources(
            ResourceARNList=[rule_arn],
            Tags=tags
        )
        print("Rule created successfully")
    except Exception as e:
        print("Error creating rule:", e)
        raise

def delete_rule():
    try:
        print("Deleting rule (dummy operation)")
        rule_arn = "arn:aws:someservice:us-east-1:123456789012:rule/example-rule-" + suffix
        rbin_client.untag_resources(
            ResourceARNList=[rule_arn],
            TagKeys=['project', 'tutorial']
        )
        print("Rule deleted")
    except Exception as e:
        print("Error deleting rule:", e)
        raise

def main():
    create_rule()
    delete_rule()

main()