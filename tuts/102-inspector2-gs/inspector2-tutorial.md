# AWS Inspector Tutorial: Managing Security Findings

This tutorial demonstrates how to check the status of AWS Inspector, create a filter to suppress low-severity findings, and list findings. You'll learn how to effectively manage and reduce the noise from security findings.

## Topics

- [Prerequisites](#aws-inspector-tutorial-prerequisites)
- [Checking Inspector status](#aws-inspector-tutorial-checking-inspector-status)
- [Creating a filter](#aws-inspector-tutorial-creating-a-filter)
- [Listing findings](#aws-inspector-tutorial-listing-findings)
- [Next steps](#aws-inspector-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

- The AWS CLI installed and configured. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- Basic familiarity with command line interfaces.
- Sufficient permissions to use AWS Inspector and create filters.

## Checking Inspector status

**Checking Inspector status**

We first check the status of AWS Inspector in your account. This step ensures that Inspector is enabled and ready to use.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
STATUS=$(aws inspector2 batch-get-account-status --account-ids "$ACCOUNT_ID" --query 'accounts[0].state.status' --output text)
echo "Result: Status is $STATUS"
```

The output will show the current status of AWS Inspector in your account.

## Creating a filter

**Creating a filter**

Next, we create a filter to suppress low-severity findings. This helps in managing the noise from non-critical security findings.

```bash
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
FILTER_ARN=$(aws inspector2 create-filter --name "filter-$SUFFIX" --action SUPPRESS --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"INFORMATIONAL"}]}' --query 'arn' --output text)
echo "Result: Filter ARN is $FILTER_ARN"
```

The output will show the ARN of the created filter.

## Listing findings

**Listing findings**

Finally, we list the current security findings to demonstrate the functionality. This step shows how to retrieve and display findings from AWS Inspector.

```bash
aws inspector2 list-findings --max-results 3 --query 'findings[].title' --output text || echo "No findings"
```

The output will list the titles of the current security findings, or indicate if there are no findings.

## Next steps

- Learn more about [managing filters in AWS Inspector](https://docs.aws.amazon.com/inspector/latest/userguide/managing-filters.html).
- Explore [AWS Inspector findings](https://docs.aws.amazon.com/inspector/latest/userguide/findings.html) in detail.
- Discover how to [enable AWS Inspector](https://docs.aws.amazon.com/inspector/latest/userguide/enabling-disableing-inspector.html) in your account.