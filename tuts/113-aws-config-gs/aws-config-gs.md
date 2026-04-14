# Add a rule and check compliance with AWS Config

## Overview

In this tutorial, you use the AWS CLI to add a managed AWS Config rule that checks whether S3 buckets have server-side encryption enabled, trigger an evaluation, and review compliance results. The tutorial requires an existing Config recorder — it does not create one because AWS allows only one recorder per account per Region.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `config:DescribeConfigurationRecorderStatus`, `config:ListDiscoveredResources`, `config:PutConfigRule`, `config:StartConfigRulesEvaluation`, `config:GetComplianceDetailsByConfigRule`, `config:DescribeComplianceByConfigRule`, and `config:DeleteConfigRule`.
- An active AWS Config recorder in the current Region. Enable one in the [AWS Config console](https://console.aws.amazon.com/config/home) if you don't have one.

## Step 1: Check Config recorder status

Verify that a Config recorder is running. The tutorial exits if no recorder is found.

```bash
RECORDER=$(aws configservice describe-configuration-recorder-status \
    --query 'ConfigurationRecordersStatus[0].{Name:name,Recording:recording}' --output table 2>/dev/null)
if [ -z "$RECORDER" ]; then
    echo "No Config recorder found. Enable AWS Config in the console first."
    exit 1
fi
echo "$RECORDER"
```

AWS Config uses a recorder to track resource configuration changes. Each account can have only one recorder per Region, so the tutorial works with your existing recorder rather than creating a new one.

## Step 2: List discovered resources

List S3 buckets that Config has discovered and is tracking.

```bash
aws configservice list-discovered-resources --resource-type AWS::S3::Bucket \
    --query 'resourceIdentifiers[:5].{Type:resourceType,Id:resourceId}' --output table
```

Config discovers resources based on the resource types your recorder is configured to track. If you see no results, your recorder may not be tracking S3 buckets.

## Step 3: Add a managed rule

Add a managed rule that checks whether S3 buckets have server-side encryption enabled.

```bash
RANDOM_ID=$(openssl rand -hex 4)
RULE_NAME="tut-s3-encryption-${RANDOM_ID}"

aws configservice put-config-rule --config-rule "{
    \"ConfigRuleName\":\"$RULE_NAME\",
    \"Source\":{\"Owner\":\"AWS\",\"SourceIdentifier\":\"S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED\"},
    \"Scope\":{\"ComplianceResourceTypes\":[\"AWS::S3::Bucket\"]}
}"
echo "Rule created: $RULE_NAME"
```

Managed rules are predefined by AWS. `S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED` checks that each S3 bucket has a default encryption configuration. The `Scope` limits evaluation to S3 buckets only.

## Step 4: Trigger evaluation

Start a rule evaluation and wait for results.

```bash
aws configservice start-config-rules-evaluation --config-rule-names "$RULE_NAME"
echo "Evaluation started — waiting 30 seconds for results..."
sleep 30
```

Evaluations run asynchronously. The 30-second wait gives Config time to evaluate your buckets. For accounts with many buckets, evaluation may take longer.

## Step 5: Check compliance details

View per-resource compliance results.

```bash
aws configservice get-compliance-details-by-config-rule --config-rule-name "$RULE_NAME" \
    --query 'EvaluationResults[:5].{Resource:EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,Compliance:ComplianceType}' \
    --output table
```

Each result shows whether a specific bucket is `COMPLIANT` or `NON_COMPLIANT`. Buckets with default encryption enabled (SSE-S3 or SSE-KMS) are compliant.

## Step 6: View compliance summary

Get the overall compliance status for the rule.

```bash
aws configservice describe-compliance-by-config-rule --config-rule-names "$RULE_NAME" \
    --query 'ComplianceByConfigRules[0].{Rule:ConfigRuleName,Compliance:Compliance.ComplianceType}' \
    --output table
```

The summary shows `COMPLIANT` only if all evaluated resources pass. If any bucket lacks encryption, the overall status is `NON_COMPLIANT`.

## Cleanup

Delete the Config rule. This does not affect your Config recorder or any S3 bucket configurations.

```bash
aws configservice delete-config-rule --config-rule-name "$RULE_NAME"
```

Config charges $0.001 per rule evaluation in most Regions. Deleting the rule stops future evaluations and charges for this rule.

The script automates all steps including cleanup:

```bash
bash aws-config-gs.sh
```

## Related resources

- [Getting started with AWS Config](https://docs.aws.amazon.com/config/latest/developerguide/getting-started.html)
- [AWS Config managed rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [Evaluating resources](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html)
- [AWS Config pricing](https://aws.amazon.com/config/pricing/)
