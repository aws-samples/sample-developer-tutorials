# Getting started with AWS WAF using the AWS CLI

This tutorial guides you through setting up AWS WAF (Web Application Firewall) using the AWS Command Line Interface (AWS CLI). You'll learn how to create a web ACL, add rules to filter web requests, and associate the web ACL with AWS resources.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/waf/latest/developerguide/waf-api-permissions-ref.html) to create and manage AWS WAF resources in your AWS account.
4. Basic understanding of web application security concepts.

### Cost information

This tutorial will incur minimal costs for the AWS WAF resources you create:
- Web ACL: $5.00 per month
- Rules: $1.00 per rule per month
- AWS Managed Rule Group: $1.60 per rule group per month
- Web Request Processing: $0.60 per million requests

The total cost for running the resources in this tutorial is approximately $0.25 per day. To avoid ongoing charges, follow the cleanup instructions at the end of the tutorial.

## Create a web ACL

A web ACL (Access Control List) is the primary resource in AWS WAF that contains rules to filter web requests. In this step, you'll create a web ACL for CloudFront distributions.

First, let's generate a random identifier to ensure unique resource names:

```bash
RANDOM_ID=$(openssl rand -hex 4)
WEB_ACL_NAME="MyWebACL-${RANDOM_ID}"
METRIC_NAME="MyWebACLMetrics-${RANDOM_ID}"

echo "Using Web ACL name: $WEB_ACL_NAME"
```

Now, create the web ACL with a default action to allow requests:

```bash
aws wafv2 create-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope "CLOUDFRONT" \
  --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME \
  --region us-east-1
```

The command creates a web ACL in the global scope for CloudFront distributions. The `--default-action Allow={}` parameter configures the web ACL to allow requests by default unless a rule explicitly blocks them. Note that CloudFront distributions require using the us-east-1 region for AWS WAF integration.

After running the command, you'll receive a response containing details about your new web ACL, including its ID, ARN, and lock token. Store these values as they'll be needed for subsequent operations:

```bash
WEB_ACL_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query "WebACLs[?Name=='$WEB_ACL_NAME'].Id" --output text)
WEB_ACL_ARN=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query "WebACLs[?Name=='$WEB_ACL_NAME'].ARN" --output text)
```

## Add a string match rule

Now that you have a web ACL, you can add rules to filter web requests. In this step, you'll add a rule that inspects the User-Agent header for a specific string.

First, get the latest lock token for your web ACL:

```bash
GET_RESULT=$(aws wafv2 get-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope CLOUDFRONT \
  --id "$WEB_ACL_ID" \
  --region us-east-1)

LOCK_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
```

The lock token is required for any update operation on a web ACL. It ensures that you're updating the latest version of the resource and prevents conflicts when multiple users are making changes simultaneously.

Now, add a string match rule that looks for "MyAgent" in the User-Agent header:

```bash
aws wafv2 update-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope "CLOUDFRONT" \
  --id "$WEB_ACL_ID" \
  --lock-token "$LOCK_TOKEN" \
  --default-action Allow={} \
  --rules '[{
    "Name": "UserAgentRule",
    "Priority": 0,
    "Statement": {
      "ByteMatchStatement": {
        "SearchString": "MyAgent",
        "FieldToMatch": {
          "SingleHeader": {
            "Name": "user-agent"
          }
        },
        "TextTransformations": [
          {
            "Priority": 0,
            "Type": "NONE"
          }
        ],
        "PositionalConstraint": "EXACTLY"
      }
    },
    "Action": {
      "Count": {}
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "UserAgentRuleMetric"
    }
  }]' \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME \
  --region us-east-1
```

This rule uses a ByteMatchStatement to inspect the User-Agent header for the exact string "MyAgent". The rule's action is set to "Count", which means it will count matching requests but won't block them. This is useful for testing rules before enforcing them.

## Add AWS managed rules

AWS WAF provides managed rule groups that contain pre-configured rules to help protect against common threats. In this step, you'll add the AWS Common Rule Set to your web ACL.

First, get the latest lock token again:

```bash
GET_RESULT=$(aws wafv2 get-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope CLOUDFRONT \
  --id "$WEB_ACL_ID" \
  --region us-east-1)

LOCK_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
```

Now, update your web ACL to include both your custom rule and the AWS Managed Rules Common Rule Set:

```bash
aws wafv2 update-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope "CLOUDFRONT" \
  --id "$WEB_ACL_ID" \
  --lock-token "$LOCK_TOKEN" \
  --default-action Allow={} \
  --rules '[{
    "Name": "UserAgentRule",
    "Priority": 0,
    "Statement": {
      "ByteMatchStatement": {
        "SearchString": "MyAgent",
        "FieldToMatch": {
          "SingleHeader": {
            "Name": "user-agent"
          }
        },
        "TextTransformations": [
          {
            "Priority": 0,
            "Type": "NONE"
          }
        ],
        "PositionalConstraint": "EXACTLY"
      }
    },
    "Action": {
      "Count": {}
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "UserAgentRuleMetric"
    }
  },
  {
    "Name": "AWS-AWSManagedRulesCommonRuleSet",
    "Priority": 1,
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesCommonRuleSet",
        "ExcludedRules": []
      }
    },
    "OverrideAction": {
      "Count": {}
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "AWS-AWSManagedRulesCommonRuleSet"
    }
  }]' \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=$METRIC_NAME \
  --region us-east-1
```

The AWS Managed Rules Common Rule Set includes rules that help protect against common web exploits. The "OverrideAction" is set to "Count", which means the rule group will only count matching requests during this testing phase.

## Associate web ACL with a CloudFront distribution

To protect a CloudFront distribution with your web ACL, you need to associate them. First, list your available CloudFront distributions:

```bash
aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,DomainName:DomainName}" --output table
```

This command displays a table of your CloudFront distributions with their IDs and domain names. Choose the distribution you want to protect and note its ID.

Now, associate your web ACL with the CloudFront distribution:

```bash
DISTRIBUTION_ID="your-distribution-id"
aws wafv2 associate-web-acl \
  --web-acl-arn "$WEB_ACL_ARN" \
  --resource-arn "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DISTRIBUTION_ID" \
  --region us-east-1
```

Replace `your-distribution-id` with the actual ID of your CloudFront distribution. This command associates your web ACL with the specified CloudFront distribution, enabling AWS WAF to inspect and filter requests to that distribution.

## Configure logging

To monitor and analyze the traffic that AWS WAF inspects, you should configure logging. This step is optional but highly recommended for production environments.

First, create an Amazon S3 bucket to store the logs:

```bash
BUCKET_NAME="aws-waf-logs-${RANDOM_ID}"
aws s3 mb s3://$BUCKET_NAME --region us-east-1
```

Now, configure AWS WAF to send logs to this bucket:

```bash
aws wafv2 put-logging-configuration \
  --resource-arn "$WEB_ACL_ARN" \
  --logging-configuration "ResourceArn=$WEB_ACL_ARN,LogDestinationConfigs=[\"arn:aws:s3:::$BUCKET_NAME\"]" \
  --region us-east-1
```

With logging configured, you can analyze the logs to understand which rules are matching requests and fine-tune your WAF configuration accordingly.

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

First, if you configured logging, delete the logging configuration:

```bash
aws wafv2 delete-logging-configuration \
  --resource-arn "$WEB_ACL_ARN" \
  --region us-east-1
```

Next, disassociate the web ACL from your CloudFront distribution:

```bash
aws wafv2 disassociate-web-acl \
  --resource-arn "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/$DISTRIBUTION_ID" \
  --region us-east-1
```

Get the latest lock token for your web ACL:

```bash
GET_RESULT=$(aws wafv2 get-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope CLOUDFRONT \
  --id "$WEB_ACL_ID" \
  --region us-east-1)

LOCK_TOKEN=$(echo "$GET_RESULT" | grep -o '"LockToken": "[^"]*' | cut -d'"' -f4)
```

Delete the web ACL:

```bash
aws wafv2 delete-web-acl \
  --name "$WEB_ACL_NAME" \
  --scope CLOUDFRONT \
  --id "$WEB_ACL_ID" \
  --lock-token "$LOCK_TOKEN" \
  --region us-east-1
```

Finally, if you created an S3 bucket for logging, delete it:

```bash
aws s3 rb s3://$BUCKET_NAME --force
```

This command deletes your web ACL and all its associated rules, as well as the S3 bucket used for logging.

## Going to production

This tutorial is designed to educate you on how the AWS WAF API works, not to provide a complete production-ready solution. When moving to a production environment, consider the following best practices:

### Security considerations

1. **Change rule actions from Count to Block**: In this tutorial, rules are set to "Count" mode for testing. In production, change them to "Block" mode to actively protect your application.

2. **Implement comprehensive logging and monitoring**: Configure logging to Amazon CloudWatch Logs or Amazon S3, and set up alerts for suspicious activity.

3. **Use rate-based rules**: Implement rate-based rules to protect against DDoS attacks by limiting the rate of requests from any single IP address.

4. **Implement AWS WAF Security Automations**: Consider deploying the [AWS WAF Security Automations](https://aws.amazon.com/solutions/implementations/aws-waf-security-automations/) solution for enhanced protection.

### Architecture best practices

1. **Infrastructure as Code**: Use AWS CloudFormation or AWS CDK to define and deploy your WAF configuration, enabling version control and consistent deployments.

2. **Rule capacity planning**: Be aware of Web ACL Capacity Units (WCUs) limits and plan your rule set accordingly.

3. **Rule optimization**: Order your rules efficiently, with cheaper rules that match frequently placed before more expensive rules.

4. **Integration with Shield Advanced**: For critical applications, consider integrating with AWS Shield Advanced for enhanced DDoS protection.

For more information on building production-ready solutions with AWS WAF, refer to the following resources:

- [AWS WAF Security Best Practices](https://docs.aws.amazon.com/waf/latest/developerguide/security-best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html)

## Next steps

Now that you've learned the basics of AWS WAF using the AWS CLI, you can explore more advanced features:

1. **Rate-based rules** - [Protect against DDoS attacks](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html) by limiting the rate of requests from any single IP address.
2. **IP sets** - [Block or allow requests](https://docs.aws.amazon.com/waf/latest/developerguide/waf-ip-set-managing.html) based on IP addresses or CIDR ranges.
3. **Regex pattern sets** - [Filter requests](https://docs.aws.amazon.com/waf/latest/developerguide/waf-regex-pattern-set-managing.html) using regular expression patterns.
4. **Custom response bodies** - [Customize responses](https://docs.aws.amazon.com/waf/latest/developerguide/customizing-the-response-for-blocked-requests.html) for blocked requests.
5. **AWS Firewall Manager** - [Centrally configure and manage](https://docs.aws.amazon.com/waf/latest/developerguide/fms-chapter.html) AWS WAF rules across multiple accounts.
