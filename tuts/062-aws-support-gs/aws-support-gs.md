# Getting started with AWS Support using the AWS CLI

This tutorial guides you through common AWS Support operations using the AWS Command Line Interface (AWS CLI). You'll learn how to check your support plan, create and manage support cases, and add communications to existing cases.

## Topics

- [Prerequisites](#prerequisites)
- [Check available services and severity levels](#check-available-services-and-severity-levels)
- [Create a support case](#create-a-support-case)
- [Manage your support cases](#manage-your-support-cases)
- [Add communications to a case](#add-communications-to-a-case)
- [Resolve a support case](#resolve-a-support-case)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also use AWS CloudShell, which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. A Business, Enterprise On-Ramp, or Enterprise Support plan. The AWS Support API is only available to accounts with these support plans. If you call the AWS Support API from an account that doesn't have one of these plans, you'll receive a `SubscriptionRequiredException` error.
4. [Sufficient permissions](https://docs.aws.amazon.com/awssupport/latest/user/security-iam.html) to create and manage AWS Support cases in your AWS account.

**Time to complete:** Approximately 15-20 minutes

**Cost:** This tutorial uses the AWS Support API, which doesn't incur additional costs beyond your AWS Support plan subscription. For pricing details, see https://aws.amazon.com/premiumsupport/pricing/.

Let's get started with using the AWS Support API through the AWS CLI.

## Check available services and severity levels

Before creating a support case, you need to know which AWS services you can create cases for and what severity levels are available. This information is required when you create a support case.

**List available AWS services**

The following command lists the AWS services for which you can create support cases:

```bash
aws support describe-services --language en
```

The output includes service codes and categories that you'll need when creating a support case. For example:

```json
{
    "services": [
        {
            "code": "general-info",
            "name": "General Info and Getting Started",
            "categories": [
                {
                    "code": "using-aws",
                    "name": "Using AWS & Services"
                },
                {
                    "code": "account-structure",
                    "name": "Account Structure"
                }
                // Additional categories...
            ]
        }
        // Additional services...
    ]
}
```

Take note of the service code and category code that best matches your support issue, as you'll need these when creating a case.

**List available severity levels**

The following command lists the available severity levels for support cases:

```bash
aws support describe-severity-levels --language en
```

The output shows the different severity levels you can assign to your support case:

```json
{
    "severityLevels": [
        {
            "code": "low",
            "name": "Low"
        },
        {
            "code": "normal",
            "name": "Normal"
        },
        {
            "code": "high",
            "name": "High"
        },
        {
            "code": "urgent",
            "name": "Urgent"
        },
        {
            "code": "critical",
            "name": "Critical"
        }
    ]
}
```

The severity level you choose affects the response time for your support case. Higher severity levels are intended for more critical issues. For more information, see [Understanding AWS Support response times](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html#response-times-for-support-cases).

## Create a support case

Now that you know the available services and severity levels, you can create a support case using the AWS CLI.

**Create a general information support case**

The following command creates a support case for general information:

```bash
aws support create-case \
    --subject "Question about AWS Services" \
    --service-code "general-info" \
    --category-code "using-aws" \
    --communication-body "I have a question about using AWS services." \
    --severity-code "low" \
    --language "en" \
    --cc-email-addresses "your-email@example.com"
```

Replace `your-email@example.com` with your email address to receive notifications about the case. Be careful about which email addresses you include, as they will receive all communications about the case, which may contain sensitive information.

The output includes the case ID, which you'll need for future operations:

```json
{
    "caseId": "case-abcd1234-2013-c4c1d2bf33c5cf47"
}
```

Make note of this case ID as you'll need it to manage your case in the following steps.

## Manage your support cases

After creating support cases, you can view and manage them using the AWS CLI.

**List your open support cases**

The following command lists all your open support cases:

```bash
aws support describe-cases \
    --include-resolved-cases false \
    --language "en"
```

The output includes details about each of your open cases:

```json
{
    "cases": [
        {
            "status": "opened",
            "ccEmailAddresses": ["your-email@example.com"],
            "timeCreated": "2025-01-13T21:31:47.774Z",
            "caseId": "case-abcd1234-2013-c4c1d2bf33c5cf47",
            "severityCode": "low",
            "language": "en",
            "categoryCode": "using-aws",
            "serviceCode": "general-info",
            "submittedBy": "your-email@example.com",
            "displayId": "1234567890",
            "subject": "Question about AWS Services"
        }
        // Additional cases...
    ]
}
```

**View a specific case by display ID**

If you know the display ID of a case, you can view its details using the following command:

```bash
aws support describe-cases \
    --display-id "1234567890" \
    --language "en"
```

This command returns detailed information about the specified case.

**View communications for a specific case**

To view the communications for a specific case, use the following command:

```bash
aws support describe-communications \
    --case-id "case-abcd1234-2013-c4c1d2bf33c5cf47" \
    --language "en"
```

Replace `case-abcd1234-2013-c4c1d2bf33c5cf47` with your actual case ID.

The output includes all communications for the specified case:

```json
{
    "communications": [
        {
            "body": "I have a question about using AWS services.",
            "caseId": "case-abcd1234-2013-c4c1d2bf33c5cf47",
            "submittedBy": "your-email@example.com",
            "timeCreated": "2025-01-13T21:31:47.774Z"
        }
        // Additional communications...
    ]
}
```

## Add communications to a case

You can add additional information to an existing support case using the AWS CLI.

**Add a communication to an existing case**

The following command adds a communication to an existing case:

```bash
aws support add-communication-to-case \
    --case-id "case-abcd1234-2013-c4c1d2bf33c5cf47" \
    --communication-body "Here is additional information about my issue." \
    --cc-email-addresses "your-email@example.com"
```

Replace `case-abcd1234-2013-c4c1d2bf33c5cf47` with your actual case ID and `your-email@example.com` with your email address.

The output confirms that the communication was added:

```json
{
    "result": true
}
```

After adding a communication, you can verify it was added by using the `describe-communications` command shown in the previous section.

## Resolve a support case

When your issue is resolved, you can close the support case using the AWS CLI.

**Resolve a support case**

The following command resolves (closes) a support case:

```bash
aws support resolve-case \
    --case-id "case-abcd1234-2013-c4c1d2bf33c5cf47"
```

Replace `case-abcd1234-2013-c4c1d2bf33c5cf47` with your actual case ID.

The output confirms that the case was resolved and includes the initial and current status:

```json
{
    "initialCaseStatus": "opened",
    "finalCaseStatus": "resolved"
}
```

If you need to reopen a resolved case, you can do so by adding a new communication to it using the `add-communication-to-case` command shown in the previous section.

## Going to production

This tutorial demonstrates basic AWS Support API operations for educational purposes. When implementing support case management in a production environment, consider the following best practices:

### Security Best Practices

1. **Use IAM roles with least privilege** - Create specific IAM roles with only the permissions needed for support case management. Here's an example policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "support:DescribeServices",
                "support:DescribeSeverityLevels",
                "support:DescribeCases",
                "support:DescribeCommunications",
                "support:CreateCase",
                "support:AddCommunicationToCase",
                "support:ResolveCase"
            ],
            "Resource": "*"
        }
    ]
}
```

2. **Be cautious with email addresses** - Only include necessary email addresses in the CC list to avoid exposing potentially sensitive information.

3. **Consider sensitive information** - Be mindful of including sensitive information in support case communications, such as account details or security configurations.

### Operational Excellence

1. **Implement error handling** - Add proper error handling and retries when making API calls.

2. **Consider API rate limits** - Be aware of potential API rate limits when making many AWS Support API calls in automated systems.

3. **Integrate with ticketing systems** - Consider integrating AWS Support case management with your organization's ticketing system for centralized tracking.

For more comprehensive guidance on building production-ready solutions, refer to:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Operations Guide](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html)

## Next steps

Now that you've learned how to use the AWS Support API through the AWS CLI, you can explore more advanced features:

- Learn how to [request a service quota increase](https://docs.aws.amazon.com/awssupport/latest/user/create-service-quota-increase.html)
- Explore [AWS Trusted Advisor](https://docs.aws.amazon.com/awssupport/latest/user/trusted-advisor.html) to optimize your AWS environment
- Understand [AWS Support response times](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html#response-times-for-support-cases) for different support plans
- Learn about [adding attachments to support cases](https://docs.aws.amazon.com/awssupport/latest/user/case-management.html#adding-attachments) for more detailed troubleshooting

For more information about AWS Support and available commands, refer to the [AWS CLI Command Reference for AWS Support](https://docs.aws.amazon.com/cli/latest/reference/support/index.html).
