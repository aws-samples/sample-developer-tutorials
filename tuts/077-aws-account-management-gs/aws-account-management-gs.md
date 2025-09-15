# Managing your AWS account with the AWS CLI

**Alternative title: Using AWS CLI commands for account management and configuration**

This tutorial guides you through common AWS account management operations using the AWS Command Line Interface (AWS CLI). You'll learn how to view account identifiers, manage account information, update alternate contacts, and control region access.

## Topics

- [Prerequisites](#prerequisites)
- [View account identifiers](#view-account-identifiers)
- [View account information](#view-account-information)
- [Manage AWS regions](#manage-aws-regions)
- [Manage alternate contacts](#manage-alternate-contacts)
- [Update account name](#update-account-name)
- [Manage root user email](#manage-root-user-email)
- [Troubleshooting common issues](#troubleshooting-common-issues)
- [Cleanup](#cleanup)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also use AWS CloudShell, which includes the AWS CLI.

2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.

3. [Sufficient permissions](https://docs.aws.amazon.com/accounts/latest/reference/security_iam_service-with-iam.html) to perform account management operations. Different operations require different permissions, which are noted in each section.

**Time to complete:** Approximately 30 minutes

**Cost:** There are no direct costs associated with the operations in this tutorial. Account management operations are free to use.

Let's get started with managing your AWS account using the CLI.

## View account identifiers

AWS assigns unique identifiers to each account that are useful for various operations and cross-account access. In this section, you'll learn how to retrieve these identifiers.

**Required permissions:**
- `sts:GetCallerIdentity` (for account ID and ARN)
- `s3:ListAllMyBuckets` (for canonical user ID)

**Find your AWS account ID**

The following command retrieves your 12-digit AWS account ID:

```bash
aws sts get-caller-identity --query Account --output text
```

Example output:
```
123456789012
```

This account ID uniquely identifies your AWS account and is used in many AWS operations, including resource ARNs and cross-account access.

**View detailed caller identity information**

To see more detailed information about your identity, including the IAM user or role you're using:

```bash
aws sts get-caller-identity
```

Example output:
```json
{
    "UserId": "AIDAXMPL123456789",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/example-user"
}
```

This information helps you confirm which account and IAM entity you're using for AWS CLI operations.

**Find your canonical user ID**

The canonical user ID is used primarily for Amazon S3 access control lists (ACLs):

```bash
aws s3api list-buckets --query Owner.ID --output text
```

Example output:
```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be
```

The canonical user ID is an obfuscated form of your AWS account ID used specifically for S3 bucket policies and ACLs.

**Tip:** Store your account ID in an environment variable for easy reference in scripts:
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "My account ID is $AWS_ACCOUNT_ID"
```

## View account information

You can retrieve various details about your AWS account using the AWS CLI. This information includes contact details and other account settings.

**Required permissions:**
- `account:GetContactInformation`

**Get account contact information**

The following command retrieves the primary contact information for your account:

```bash
aws account get-contact-information
```

Example output:
```json
{
    "ContactInformation": {
        "AddressLine1": "123 Example Street",
        "City": "Seattle",
        "CountryCode": "US",
        "FullName": "Example Company",
        "PhoneNumber": "+1-555-555-0100",
        "PostalCode": "98101",
        "StateOrRegion": "WA"
    }
}
```

This information represents the primary contact details associated with your AWS account. To update this information, you would use the `put-contact-information` command.

**Best practice:** Ensure your contact information is up-to-date so that AWS can reach you regarding important account notifications, security alerts, and billing information.

## Manage AWS regions

AWS allows you to control which regions are enabled for your account. This section shows you how to list regions and manage their status.

**Required permissions:**
- `account:ListRegions`
- `account:GetRegionOptStatus`
- `account:EnableRegion`
- `account:DisableRegion`

**List available regions**

To see all available AWS regions and their current status:

```bash
aws account list-regions
```

Example output (truncated):
```json
{
    "Regions": [
        {
            "RegionName": "us-east-1",
            "RegionOptStatus": "ENABLED_BY_DEFAULT"
        },
        {
            "RegionName": "af-south-1",
            "RegionOptStatus": "DISABLED"
        }
    ]
}
```

The output shows all AWS regions and whether they are enabled, disabled, or enabled by default for your account.

**Display regions in a more readable format**

For a cleaner, more readable display of regions and their status, you can use this command:

```bash
aws account list-regions --query 'Regions[*].[RegionName,RegionOptStatus]' --output text | while read -r region status; do
    printf "%-15s | %s\n" "$region" "$status"
done
```

Example output:
```
us-east-1       | ENABLED_BY_DEFAULT
us-east-2       | ENABLED_BY_DEFAULT
us-west-1       | ENABLED_BY_DEFAULT
us-west-2       | ENABLED_BY_DEFAULT
af-south-1      | DISABLED
ap-east-1       | DISABLED
```

This format makes it easier to scan through the list and quickly identify which regions are enabled or disabled.

**Check the status of a specific region**

To check the status of a particular region:

```bash
aws account get-region-opt-status --region-name af-south-1
```

Example output:
```json
{
    "RegionName": "af-south-1",
    "RegionOptStatus": "DISABLED"
}
```

This shows whether the specified region is currently enabled or disabled for your account.

**Enable a region**

If you have the necessary permissions, you can enable a region with:

```bash
aws account enable-region --region-name af-south-1
```

This command doesn't produce output if successful. The operation is asynchronous, so you should check the status afterward:

```bash
aws account get-region-opt-status --region-name af-south-1
```

**Disable a region**

Similarly, you can disable a region if it's not needed:

```bash
aws account disable-region --region-name af-south-1
```

**Important:** Disabling a region that contains resources will make those resources inaccessible via IAM, though you'll still be charged for them. Always ensure you've migrated or deleted all resources in a region before disabling it.

## Manage alternate contacts

AWS allows you to specify alternate contacts for billing, operations, and security purposes. These contacts receive important communications from AWS.

**Required permissions:**
- `account:GetAlternateContact`
- `account:PutAlternateContact`
- `account:DeleteAlternateContact`

**View alternate contacts**

To view your current billing alternate contact:

```bash
aws account get-alternate-contact --alternate-contact-type BILLING
```

Example output:
```json
{
    "AlternateContact": {
        "AlternateContactType": "BILLING",
        "EmailAddress": "billing@example.com",
        "Name": "Billing Team",
        "PhoneNumber": "+1-555-555-1234",
        "Title": "Finance Manager"
    }
}
```

You can also view operations and security contacts by changing the `--alternate-contact-type` parameter to `OPERATIONS` or `SECURITY`.

**Add or update an alternate contact**

To add or update an alternate contact:

```bash
aws account put-alternate-contact \
    --alternate-contact-type OPERATIONS \
    --email-address operations@example.com \
    --name "Operations Team" \
    --phone-number "+1-555-555-5678" \
    --title "Operations Manager"
```

This command doesn't produce output if successful. If you perform this operation on a contact type that already exists, it will update the existing contact.

**Delete an alternate contact**

To remove an alternate contact:

```bash
aws account delete-alternate-contact --alternate-contact-type SECURITY
```

This command doesn't produce output if successful.

**Best practice:** Use distribution lists rather than individual email addresses for alternate contacts to ensure notifications are received even when staff changes occur.

## Update account name

You can update your AWS account name to better reflect its purpose or organization.

**Required permissions:**
- `account:PutAccountName`

**Update account name for a standalone account**

```bash
aws account put-account-name --account-name "Production Account"
```

This command doesn't produce output if successful. The account name will be updated immediately, though it may take some time to reflect across all AWS services.

**Update account name for a member account in an organization**

If you have the necessary permissions in an AWS Organization:

```bash
aws account put-account-name --account-id 123456789012 --account-name "Production Account"
```

This allows organization administrators to maintain consistent naming conventions across all accounts.

**Best practice:** Use a consistent naming convention for your accounts, such as `<department>-<environment>-<purpose>` (e.g., "finance-prod-reporting").

## Manage root user email

For security and administrative purposes, you might need to update the root user email address. This can only be done through a multi-step process.

**Required permissions for organization administrators:**
- `account:GetPrimaryEmail`
- `account:StartPrimaryEmailUpdate`
- `account:AcceptPrimaryEmailUpdate`

**For member accounts in an organization**

Step 1: Start the email update process:

```bash
aws account start-primary-email-update --account-id 123456789012 --primary-email new-email@example.com
```

Step 2: After receiving the one-time password (OTP) at the new email address:

```bash
aws account accept-primary-email-update --account-id 123456789012 --otp 12345678 --primary-email new-email@example.com
```

This two-step verification process ensures that only authorized users can update the root email address.

**Note:** For standalone accounts, the root user email can only be updated through the AWS Management Console by signing in as the root user.

## Troubleshooting common issues

Here are solutions to common issues you might encounter when using the AWS CLI for account management:

**Permission denied errors**

If you see an error like:
```
An error occurred (AccessDeniedException) when calling the GetAlternateContact operation: User: arn:aws:iam::123456789012:user/example-user is not authorized to perform: account:GetAlternateContact
```

Solution: Ensure your IAM user or role has the necessary permissions. Add the required permission to your IAM policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "account:GetAlternateContact",
            "Resource": "*"
        }
    ]
}
```

**Organization-related errors**

If you see an error like:
```
An error occurred (AccessDeniedException) when calling the EnableRegion operation: Account region opt status can only be modified through Isengard.
```

Solution: Ensure you're using an account with the appropriate permissions in the organization. For organization operations, you typically need to use the management account or a delegated administrator account.

**Rate limiting errors**

If you see an error like:
```
An error occurred (TooManyRequestsException) when calling the EnableRegion operation
```

Solution: Implement exponential backoff in your scripts or wait a few minutes before retrying the operation.

## Cleanup

Most operations in this tutorial are read-only and don't create resources that need cleanup. However, if you've made changes to your account configuration, consider the following:

**Regions you've enabled**

If you enabled regions for testing purposes and don't plan to use them, you should disable them to prevent accidental resource creation:

```bash
aws account disable-region --region-name af-south-1
```

**Alternate contacts you've added**

If you added test alternate contacts, you might want to remove them:

```bash
aws account delete-alternate-contact --alternate-contact-type OPERATIONS
```

**Account name changes**

If you changed your account name for testing, you might want to revert it:

```bash
aws account put-account-name --account-name "Original Account Name"
```

## Next steps

Now that you've learned how to manage your AWS account using the AWS CLI, you might want to explore these related topics:

- [Managing AWS account alternate contacts](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-update-contact-alternate.html)
- [Enabling and disabling AWS Regions](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html)
- [Updating your AWS account name](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-update-acct-name.html)
- [Updating the root user email address](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-update-root-user-email.html)
- [Viewing AWS account identifiers](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-identifiers.html)
- [Setting up AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tutorials_basic.html) for managing multiple accounts
