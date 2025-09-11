# Getting started with IAM Identity Center using the AWS CLI

This tutorial guides you through setting up AWS IAM Identity Center (successor to AWS Single Sign-On) using the AWS Command Line Interface (AWS CLI). IAM Identity Center provides a central place to manage access to multiple AWS accounts and business applications.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with administrative permissions. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. For organization instance (recommended): Access to the AWS Organizations management account.
3. For account instance: Administrative access to the AWS account where you want to enable IAM Identity Center.
4. Basic familiarity with command line interfaces and identity management concepts.
5. Estimated time to complete: 30-45 minutes.

**Cost information**: IAM Identity Center is provided at no additional charge. However, if users are granted access to AWS resources through IAM Identity Center, those resources may incur charges based on their usage.

## Enable IAM Identity Center

The first step is to enable IAM Identity Center in your AWS account. When you enable IAM Identity Center, you'll create an instance that can be either an organization instance or an account instance.

**Check if IAM Identity Center is already enabled**

Before creating a new instance, check if IAM Identity Center is already enabled in your account.

```bash
aws sso-admin list-instances
```

If the command returns an empty array (`[]`), IAM Identity Center is not yet enabled. If it returns instance information, you can use the existing instance.

**Important considerations for organization management accounts**

If you're using the management account of an AWS organization, IAM Identity Center must be enabled through the AWS Console first. The CLI cannot enable IAM Identity Center for organization management accounts.

To enable IAM Identity Center for an organization:

1. Go to the AWS Console: https://console.aws.amazon.com/
2. Navigate to IAM Identity Center: https://console.aws.amazon.com/singlesignon
3. Click 'Enable' to enable IAM Identity Center for your organization

**Create an IAM Identity Center instance (for non-organization management accounts)**

For standalone accounts or member accounts in an organization, you can create a new IAM Identity Center instance using the following command:

```bash
aws sso-admin create-instance --name "MyIdentityCenter" --tags Key=Purpose,Value=Tutorial
```

The instance type (organization or account) is determined automatically based on whether your AWS account is part of an organization and whether it's the management account. Organization instances are created when you enable IAM Identity Center from the management account of an AWS organization.

After running the command, wait a few moments for the instance to be created and initialized. You can check the status by listing the instances again:

```bash
aws sso-admin list-instances
```

From the output, note the `InstanceArn` and `IdentityStoreId` values, as you'll need them for subsequent commands.

## Create users and groups

After enabling IAM Identity Center, you can create users and groups in the identity store.

**Create a user**

Create a user in the IAM Identity Center identity store:

```bash
aws identitystore create-user \
  --identity-store-id "d-9a67xmpl" \
  --user-name "demo-user" \
  --display-name "Demo User" \
  --name "GivenName=Demo,FamilyName=User" \
  --emails "Value=demo-user@example.com,Type=Work,Primary=true"
```

The command returns a user ID that you'll need for subsequent operations. Save this ID for later use.

**Create a group**

Create a group to organize your users:

```bash
aws identitystore create-group \
  --identity-store-id "d-9a67xmpl" \
  --display-name "Developers" \
  --description "Development team members"
```

The command returns a group ID that you'll need for subsequent operations. Save this ID for later use.

**Add user to group**

Add the user to the group you created:

```bash
aws identitystore create-group-membership \
  --identity-store-id "d-9a67xmpl" \
  --group-id "610b45a0-20f1-707e-8f94-8692c57xmpl" \
  --member-id "UserId=21ebd5e0-0091-70b1-570f-8e4058d9xmpl"
```

Replace the identity store ID, group ID, and user ID with your actual values. The command returns a membership ID that confirms the user has been added to the group.

## Set up user access to AWS accounts (organization instance only)

If you're using an organization instance of IAM Identity Center, you can assign users or groups access to AWS accounts using permission sets. This step is only applicable for organization instances.

**Create a permission set**

Create a permission set that defines the level of access:

```bash
aws sso-admin create-permission-set \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --name "DeveloperAccess" \
  --description "Developer access to AWS resources" \
  --session-duration "PT8H"
```

The session duration "PT8H" specifies that sessions will last for 8 hours. The command returns a permission set ARN that you'll need for subsequent operations.

**Attach AWS managed policy to permission set**

Attach an AWS managed policy to the permission set:

```bash
aws sso-admin attach-managed-policy-to-permission-set \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234" \
  --managed-policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
```

This example attaches the ReadOnlyAccess policy, which provides read-only access to all AWS resources.

**Assign access to AWS account**

Assign the group to an AWS account with the permission set:

```bash
aws sso-admin create-account-assignment \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --target-id "123456789012" \
  --target-type AWS_ACCOUNT \
  --principal-type GROUP \
  --principal-id "610b45a0-20f1-707e-8f94-8692c57xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234"
```

Replace the target ID with your AWS account ID. This command assigns the specified group access to the AWS account with the permissions defined in the permission set.

This operation is asynchronous and returns a request ID. You can check the status of the assignment using:

```bash
aws sso-admin describe-account-assignment-creation-status \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --account-assignment-creation-request-id "request-id-from-previous-command"
```

Wait for the status to show `SUCCEEDED` before proceeding to the next step.

**Provision permission set to account**

After creating the assignment, provision the permission set to the account:

```bash
aws sso-admin provision-permission-set \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234" \
  --target-id "123456789012" \
  --target-type AWS_ACCOUNT
```

This command creates the necessary IAM roles in the target account to implement the permissions defined in the permission set.

This operation is also asynchronous and returns a request ID. You can check the status using:

```bash
aws sso-admin describe-permission-set-provisioning-status \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --provision-request-id "request-id-from-previous-command"
```

Wait for the status to show `SUCCEEDED` before proceeding.

## Set up user access to applications

IAM Identity Center allows you to grant users access to applications. This section shows how to create and assign a SAML application.

**Create a SAML application**

Create a SAML 2.0 application in IAM Identity Center using an application provider from the catalog:

```bash
aws sso-admin create-application \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --application-provider-arn "arn:aws:sso::aws:applicationProvider/catalog/Box" \
  --name "MyCustomApp" \
  --description "My custom SAML 2.0 application" \
  --portal-options Visibility=ENABLED
```

This example uses the Box application provider from the AWS application catalog. You can list available application providers using:

```bash
aws sso-admin list-application-providers
```

The command returns an application ARN that you'll need for subsequent operations.

**Assign user to application**

Assign a user to the application:

```bash
aws sso-admin create-application-assignment \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --application-arn "arn:aws:sso:::application/ssoins-668445886c0xmpl/app-abcd1234" \
  --principal-type USER \
  --principal-id "21ebd5e0-0091-70b1-570f-8e4058d9xmpl"
```

This command grants the specified user access to the application.

## Access the AWS access portal

After setting up IAM Identity Center, users can access the AWS access portal to sign in to their assigned applications and AWS accounts.

**Get the AWS access portal URL**

Retrieve the AWS access portal URL using the Identity Store ID:

```bash
# The portal URL follows this format: https://{IdentityStoreId}.awsapps.com/start
# For example, if your Identity Store ID is d-9a67xmpl:
echo "https://d-9a67xmpl.awsapps.com/start"
```

Alternatively, you can retrieve the instance access URL directly:

```bash
aws sso-admin describe-instance \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --query 'Instance.InstanceAccessUrl' \
  --output text
```

The command returns the URL for the AWS access portal, which will be in the format `https://your-domain.awsapps.com/start`.

Users will need to activate their user credentials before they can sign in to the AWS access portal. They will receive an email with instructions to set up their password.

## Troubleshooting

Here are some common issues you might encounter when setting up IAM Identity Center:

**Issue**: "The operation is not supported for this Identity Center instance" error when creating a permission set.

**Solution**: This error occurs when you try to create a permission set for an account instance. Permission sets are only supported for organization instances. Ensure you're using an organization instance if you need to create permission sets.

**Issue**: Asynchronous operations don't complete as expected.

**Solution**: Many IAM Identity Center operations are asynchronous, including account assignments and permission set provisioning. Always check the operation status using the appropriate describe command and wait for the status to show `SUCCEEDED` before proceeding to the next step.

**Issue**: Application creation fails with provider ARN errors.

**Solution**: When creating applications, ensure you're using a valid application provider ARN from the AWS catalog. Use `aws sso-admin list-application-providers` to see available providers.

**Issue**: Instance takes time to initialize after creation.

**Solution**: After creating a new IAM Identity Center instance, wait 30-60 seconds for it to fully initialize before attempting to create users, groups, or other resources.

**Issue**: Cannot create IAM Identity Center instance from organization management account.

**Solution**: For organization management accounts, IAM Identity Center must be enabled through the AWS Console first. The CLI cannot enable IAM Identity Center for organization management accounts. Follow these steps:
1. Go to https://console.aws.amazon.com/singlesignon
2. Click 'Enable' to enable IAM Identity Center for your organization
3. Then use the CLI commands or run the script with `--skip-enable`

**Issue**: User doesn't receive activation email.

**Solution**: Check that the email address is correct and that emails from AWS aren't being filtered as spam. You can also reset the user's password through the IAM Identity Center console.

**Issue**: "AccessDeniedException" when running commands.

**Solution**: Ensure you have the necessary permissions to manage IAM Identity Center. For organization instances, you need administrative permissions in the management account.

## Clean up resources

When you're finished with the resources created in this tutorial, you should clean them up to avoid potential issues with resource limits.

**Delete application assignment**

Delete the application assignment:

```bash
aws sso-admin delete-application-assignment \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --application-arn "arn:aws:sso:::application/ssoins-668445886c0xmpl/app-abcd1234" \
  --principal-id "21ebd5e0-0091-70b1-570f-8e4058d9xmpl" \
  --principal-type USER
```

**Delete application**

Delete the application:

```bash
aws sso-admin delete-application \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --application-arn "arn:aws:sso:::application/ssoins-668445886c0xmpl/app-abcd1234"
```

**Delete account assignment (organization instance only)**

If you created an account assignment, delete it:

```bash
aws sso-admin delete-account-assignment \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234" \
  --target-id "123456789012" \
  --target-type AWS_ACCOUNT \
  --principal-id "610b45a0-20f1-707e-8f94-8692c57xmpl" \
  --principal-type GROUP
```

This operation is asynchronous. You can check the deletion status using:

```bash
aws sso-admin describe-account-assignment-deletion-status \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --account-assignment-deletion-request-id "request-id-from-previous-command"
```

**Detach managed policy (organization instance only)**

If you attached a managed policy to a permission set, detach it:

```bash
aws sso-admin detach-managed-policy-from-permission-set \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234" \
  --managed-policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
```

**Delete permission set (organization instance only)**

If you created a permission set, delete it:

```bash
aws sso-admin delete-permission-set \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl" \
  --permission-set-arn "arn:aws:sso:::permissionSet/ssoins-668445886c0xmpl/ps-abcd1234"
```

**Delete group membership**

Delete the group membership:

```bash
aws identitystore delete-group-membership \
  --identity-store-id "d-9a67xmpl" \
  --membership-id "010ba5a0-a051-7026-f7c3-042d5b76xmpl"
```

**Delete group**

Delete the group:

```bash
aws identitystore delete-group \
  --identity-store-id "d-9a67xmpl" \
  --group-id "610b45a0-20f1-707e-8f94-8692c57xmpl"
```

**Delete user**

Delete the user:

```bash
aws identitystore delete-user \
  --identity-store-id "d-9a67xmpl" \
  --user-id "21ebd5e0-0091-70b1-570f-8e4058d9xmpl"
```

**Delete IAM Identity Center instance**

Finally, delete the IAM Identity Center instance:

```bash
aws sso-admin delete-instance \
  --instance-arn "arn:aws:sso:::instance/ssoins-668445886c0xmpl"
```

## Automated setup script

For convenience, you can use the provided automated setup script that performs all the steps in this tutorial. The script includes comprehensive error handling, logging, and cleanup functionality.

**Running the automated script**

If you have an organization management account where IAM Identity Center is already enabled:

```bash
./2-cli-script-v9-fixed.sh --skip-enable
```

For standalone accounts or if IAM Identity Center is not yet enabled:

```bash
./2-cli-script-v9-fixed.sh
```

**Script features**

The automated script includes:

- Automatic detection of organization vs. account instances
- Comprehensive error handling and logging
- Waiting for asynchronous operations to complete
- Resource tracking for easy cleanup
- Interactive cleanup confirmation
- Detailed logging to a timestamped log file

**Script options**

- `--help` or `-h`: Display help information
- `--skip-enable`: Skip the IAM Identity Center enablement check (use when already enabled)

The script will create unique resource names using random suffixes to avoid naming conflicts and will prompt you at the end whether you want to clean up all created resources.

## Going to production

This tutorial is designed to help you learn how to use the IAM Identity Center API through the AWS CLI. For production deployments, consider the following best practices:

### Security best practices

1. **Enable Multi-Factor Authentication (MFA)**: Configure MFA for all IAM Identity Center users to add an extra layer of security.

2. **Implement strong password policies**: Configure password policies to enforce strong passwords for your users.

3. **Follow the principle of least privilege**: Create custom permission sets that grant only the specific permissions required for each role, rather than using broad managed policies like ReadOnlyAccess.

4. **Enable CloudTrail logging**: Set up AWS CloudTrail to log IAM Identity Center activities for auditing and monitoring purposes.

5. **Use corporate email domains**: Use your organization's email domain for user accounts rather than public email providers.

### Architecture best practices

1. **Automate with Infrastructure as Code**: Use AWS CloudFormation or Terraform to automate the deployment and management of IAM Identity Center configurations.

2. **Implement a multi-account strategy**: Design a well-structured AWS account strategy with appropriate organizational units (OUs) and permission sets.

3. **Plan for scale**: For large organizations, consider batch operations and pagination when managing large sets of identities.

4. **Implement monitoring and alerting**: Set up monitoring for authentication failures and suspicious activities.

5. **Develop a disaster recovery plan**: Create procedures for backing up and restoring your identity configurations.

For more information on security and architecture best practices, refer to:
- [AWS Identity and Access Management Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Next steps

Now that you've learned the basics of setting up IAM Identity Center using the AWS CLI, explore other IAM Identity Center features:

1. [Using Active Directory as an identity source](https://docs.aws.amazon.com/singlesignon/latest/userguide/gs-ad.html) - Connect your existing Active Directory to IAM Identity Center.
2. [Configuring external identity providers](https://docs.aws.amazon.com/singlesignon/latest/userguide/tutorials.html) - Connect IAM Identity Center to external identity providers like Okta or Azure AD.
3. [Managing permission sets](https://docs.aws.amazon.com/singlesignon/latest/userguide/permissionsetsconcept.html) - Create and manage permission sets for fine-grained access control.
4. [Integrating AWS CLI with IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/integrating-aws-cli.html) - Configure the AWS CLI to use IAM Identity Center for authentication.
5. [Setting up customer managed applications](https://docs.aws.amazon.com/singlesignon/latest/userguide/customermanagedapps.html) - Integrate your custom applications with IAM Identity Center.
