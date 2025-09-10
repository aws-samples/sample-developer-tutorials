# Creating and managing Amazon WorkSpaces Personal using the AWS CLI

This tutorial guides you through creating and managing Amazon WorkSpaces Personal using the AWS Command Line Interface (AWS CLI). You'll learn how to register a directory with WorkSpaces, create a WorkSpace for a user, check its status, and perform basic management tasks.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. An AWS account with permissions to create and manage WorkSpaces resources.

3. A directory service already set up in a supported AWS Region. WorkSpaces Personal requires one of the following directory types:
   - Simple AD directory
   - AWS Directory Service for Microsoft Active Directory (AWS Managed Microsoft AD)
   - AD Connector to connect to an existing Microsoft Active Directory
   - A trust relationship between AWS Managed Microsoft AD and your on-premises domain
   - A dedicated directory using Microsoft Entra ID or another identity provider through IAM Identity Center

4. A user account in your directory that will be assigned to the WorkSpace.

5. Sufficient [service quotas](https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-limits.html) for creating WorkSpaces in your AWS account.

6. Basic familiarity with command line interfaces.

### Cost considerations

Running resources created in this tutorial will incur costs in your AWS account. Approximate costs include:

- **WorkSpaces Personal (Standard bundle with Windows)**:
  - AlwaysOn mode: approximately $35/month
  - AutoStop mode: approximately $9.75/month + $0.26/hour of usage

- **Directory Services** (if you need to create one):
  - AWS Simple AD (Small): approximately $36.50/month
  - AWS Managed Microsoft AD (Standard): approximately $292/month
  - AD Connector: approximately $36.50/month

Additional charges may apply for data transfer, increased storage volumes, and application licensing. For the most current pricing information, see the [Amazon WorkSpaces Pricing page](https://aws.amazon.com/workspaces/pricing/).

## Verify WorkSpaces availability in your region

Amazon WorkSpaces is not available in all AWS Regions. Before proceeding, verify that WorkSpaces is available in your chosen region by checking the [WorkSpaces supported regions](https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-regions.html) in the documentation.

Once you've confirmed WorkSpaces availability, set your AWS region:

```
export AWS_DEFAULT_REGION=us-west-2
```

Replace `us-west-2` with your preferred region where WorkSpaces is available.

## Register a directory with WorkSpaces

Before creating WorkSpaces, you need to register your directory with the WorkSpaces service. First, check if your directory is already registered:

```
aws workspaces describe-workspace-directories
```

This command lists all directories that are registered with WorkSpaces. If your directory is not listed, you need to register it:

```
aws workspaces register-workspace-directory --directory-id d-abcd1234
```

Replace `d-abcd1234` with your actual directory ID. The registration process may take a few minutes to complete. You can check the registration status with:

```
aws workspaces describe-workspace-directories --directory-ids d-abcd1234
```

Look for the `"State": "REGISTERED"` field in the output to confirm that registration is complete.

## List available WorkSpaces bundles

A bundle defines the hardware and software configuration for your WorkSpace. To list all available bundles provided by AWS:

```
aws workspaces describe-workspace-bundles --owner AMAZON
```

This command returns detailed information about all available bundles. For a more concise list showing just the bundle names and IDs:

```
aws workspaces describe-workspace-bundles --owner AMAZON --query "Bundles[*].[Name, BundleId]" --output text
```

Note the bundle ID that you want to use for creating your WorkSpace.

## Create a WorkSpace

Now you can create a WorkSpace for a user in your directory. You have two options for the running mode:

**Option 1: Create an AlwaysOn WorkSpace (billed monthly)**

```
aws workspaces create-workspaces --workspaces DirectoryId=d-abcd1234,UserName=jdoe,BundleId=wsb-abcd1234
```

**Option 2: Create an AutoStop WorkSpace (billed hourly)**

```
aws workspaces create-workspaces --workspaces DirectoryId=d-abcd1234,UserName=jdoe,BundleId=wsb-abcd1234,WorkspaceProperties={RunningMode=AUTO_STOP}
```

You can also specify additional properties like timeout duration and add tags:

```
aws workspaces create-workspaces --workspaces DirectoryId=d-abcd1234,UserName=jdoe,BundleId=wsb-abcd1234,WorkspaceProperties={RunningMode=AUTO_STOP,RunningModeAutoStopTimeoutInMinutes=60},Tags=[{Key=Department,Value=IT}]
```

Replace the following values with your actual information:
- `d-abcd1234`: Your directory ID
- `jdoe`: The username of the user in your directory
- `wsb-abcd1234`: The bundle ID you selected

The command returns a response that includes the WorkSpace ID. Note this ID for future management operations.

## Check the status of your WorkSpace

Creating a WorkSpace can take 20 minutes or more. To check the status of your WorkSpace:

```
aws workspaces describe-workspaces --workspace-ids ws-abcd1234
```

Replace `ws-abcd1234` with your actual WorkSpace ID. Look for the `"State"` field in the output:
- `PENDING`: The WorkSpace is still being created
- `AVAILABLE`: The WorkSpace is ready to use
- `ERROR`: There was a problem creating the WorkSpace

You can also list all WorkSpaces in a specific directory:

```
aws workspaces describe-workspaces --directory-id d-abcd1234
```

## Troubleshooting WorkSpace creation

If your WorkSpace creation fails or gets stuck in an error state, here are some common issues and solutions:

1. **Insufficient service quotas**: Check your [WorkSpaces service quotas](https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-limits.html) and request an increase if needed.

2. **Directory issues**: Ensure your directory is properly configured and accessible.

3. **User not found**: Verify that the username exists in your directory.

4. **Network connectivity**: Check that your VPC and subnets are properly configured for WorkSpaces.

5. **Region availability**: Confirm that WorkSpaces is available in your selected region.

If you encounter an error, you can get more details using:

```
aws workspaces describe-workspace-errors --workspace-ids ws-abcd1234
```

## Manage your WorkSpace

After your WorkSpace is created, you can perform various management tasks:

**Modify WorkSpace properties**

Change the running mode from AutoStop to AlwaysOn:

```
aws workspaces modify-workspace-properties --workspace-id ws-abcd1234 --workspace-properties RunningMode=ALWAYS_ON
```

**Reboot a WorkSpace**

If your WorkSpace becomes unresponsive, you can reboot it:

```
aws workspaces reboot-workspaces --reboot-workspace-requests WorkspaceId=ws-abcd1234
```

**Rebuild a WorkSpace**

If you need to restore the operating system to its original state:

```
aws workspaces rebuild-workspaces --rebuild-workspace-requests WorkspaceId=ws-abcd1234
```

## Invitation emails

When you create a WorkSpace, an invitation email is automatically sent to the user in most cases. However, invitation emails aren't sent automatically if you're using AD Connector or a trust relationship, or if the user already exists in Active Directory.

In these cases, you need to manually send an invitation email through the AWS Management Console. For more information, see [Send an invitation email](https://docs.aws.amazon.com/workspaces/latest/adminguide/manage-workspaces-users.html#send-invitation).

## Clean up resources

When you no longer need your WorkSpace, you can delete it to avoid incurring charges:

```
aws workspaces terminate-workspaces --terminate-workspace-requests WorkspaceId=ws-abcd1234
```

If you registered a directory specifically for this tutorial and no longer need it, you can deregister it:

```
aws workspaces deregister-workspace-directory --directory-id d-abcd1234
```

Note that deregistering a directory does not delete it. The directory will still exist in AWS Directory Service, but it will no longer be available for use with WorkSpaces.

## Going to production

This tutorial is designed to help you learn how to use the AWS CLI to create and manage WorkSpaces. For production environments, consider the following additional factors:

### Security considerations

1. **Implement least privilege access**: Create IAM policies that grant only the permissions needed for specific roles.

2. **Configure network security**: Use security groups and IP access control groups to restrict network access to WorkSpaces.

3. **Enable encryption**: Configure encryption for WorkSpaces volumes and data in transit.

4. **Implement multi-factor authentication**: Enable MFA for WorkSpaces users.

5. **Set up monitoring and logging**: Configure CloudTrail and CloudWatch to monitor WorkSpaces activity.

For more information, see the [Amazon WorkSpaces Security guide](https://docs.aws.amazon.com/workspaces/latest/adminguide/workspaces-security.html).

### Architecture best practices

1. **Automation**: Use AWS CloudFormation or Terraform to automate WorkSpaces deployment.

2. **High availability**: Configure cross-Region redirection for disaster recovery.

3. **Scalability**: Create custom images and bundles for consistent deployment at scale.

4. **Cost optimization**: Implement WorkSpaces Savings Plans and choose appropriate running modes.

5. **Monitoring and management**: Set up proactive monitoring and automated management.

For more information on building production-ready WorkSpaces environments, see:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Amazon WorkSpaces Best Practices](https://docs.aws.amazon.com/workspaces/latest/adminguide/best-practices.html)

## Next steps

Now that you've learned how to create and manage WorkSpaces using the AWS CLI, you might want to explore:

- [Customize your WorkSpace](https://docs.aws.amazon.com/workspaces/latest/userguide/customize-workspaces.html)
- [Enable self-service WorkSpace management capabilities for your users](https://docs.aws.amazon.com/workspaces/latest/adminguide/enable-user-self-service-workspace-management.html)
- [Set up cross-Region redirection for your WorkSpaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/cross-region-redirection.html)
- [Implement IP access control groups for your WorkSpaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces-ip-access-control-groups.html)
- [Enable multi-factor authentication for WorkSpaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/configure-workspace-authentication.html)
