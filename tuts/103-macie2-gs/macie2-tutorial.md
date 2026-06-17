# AWS Macie Tutorial

This tutorial demonstrates how to use AWS Macie to manage sensitive data in your AWS environment. We will cover checking session status, listing findings, creating allow lists, classification jobs, custom data identifiers, findings filters, invitations, and members.

## Topics

- [Prerequisites](#prerequisites)
- [Check Macie session status](#check-macie-session-status)
- [List findings](#list-findings)
- [Create allow list](#create-allow-list)
- [Create classification job](#create-classification-job)
- [Create custom data identifier](#create-custom-data-identifier)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/macie/latest/user/security_iam_service-with-iam.html) to use AWS Macie.

## Check Macie session status

Checking the status of your Macie session is important to ensure that the service is enabled and running. This step verifies that Macie is active and ready for further operations.

**Check Macie session status**

```bash
aws macie2 get-macie-session --query'status' --output text
```

After running the command, you should see the current status of your Macie session.

## List findings

Listing findings helps you understand the current security posture of your data in AWS. This step retrieves a list of findings to show the number of security issues detected by Macie.

**List findings**

```bash
aws macie2 list-findings --finding-criteria '{}' --max-results 10 --query 'length(findings)' --output text
```

After running the command, you should see the number of findings detected by Macie.

## Create allow list

An allow list helps Macie ignore specific data patterns that are known to be safe. This step creates an allow list to exclude certain regex patterns from Macie scans.

**Create allow list**

```bash
aws macie2 create-allow-list --criteria '{"regex":{"regexString":"example"}}' --description "Example Allow List"
```

After running the command, you should see a message indicating that the allow list has been created.

## Create classification job

A classification job scans your S3 buckets for sensitive data and generates findings. This step creates a classification job to scan a specified S3 bucket for sensitive data.

**Create classification job**

```bash
aws macie2 create-classification-job --job-name "ExampleJob" --s3-job-definition '{"bucketDefinitions":[{"bucketName":"example-bucket"}]}' --query 'jobId' --output text
```

After running the command, you should see the ID of the created classification job.

## Create custom data identifier

A custom data identifier allows you to define specific patterns of sensitive data that Macie should detect. This step creates a custom data identifier to recognize a specific regex pattern in your data.

**Create custom data identifier**

```bash
aws macie2 create-custom-data-identifier --name "ExampleIdentifier" --regex "example" --description "Example Custom Data Identifier" --query 'id' --output text
```

After running the command, you should see the ID of the created custom data identifier.

## Next steps

- Learn more about [Macie findings](https://docs.aws.amazon.com/macie/latest/user/findings.html).
- Explore [Macie allow lists](https://docs.aws.amazon.com/macie/latest/user/allow-lists.html).
- Discover how to [create classification jobs](https://docs.aws.amazon.com/macie/latest/user/classification-jobs.html).
- Understand [custom data identifiers](https://docs.aws.amazon.com/macie/latest/user/custom-data-identifiers.html).
- Get to know [Macie findings filters](https://docs.aws.amazon.com/macie/latest/user/findings-filter.html).
- Invite and manage [Macie members](https://docs.aws.amazon.com/macie/latest/user/members.html).