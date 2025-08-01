# Setting up AWS Systems Manager using the AWS CLI

This tutorial guides you through setting up AWS Systems Manager for a single account and region using the AWS Command Line Interface (AWS CLI). You'll learn how to create the necessary IAM permissions, enable Systems Manager features, and configure the unified console experience.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Administrative permissions to create IAM policies and roles.
4. Basic familiarity with command line interfaces and AWS services.

**Time to complete:** Approximately 20-30 minutes

**Cost:** The AWS Systems Manager features used in this tutorial (unified console, Default Host Management Configuration, inventory collection, and automatic agent updates) are available at no additional cost. You only pay for the AWS resources that are managed by Systems Manager, such as EC2 instances, which are not created as part of this tutorial.

Let's get started with setting up AWS Systems Manager using the CLI.

## Option 1: Automated setup using the provided script

For a quick and automated setup, you can use the provided script that handles all the steps automatically, including error handling and cleanup:

```bash
# Download and run the automated setup script
curl -O https://raw.githubusercontent.com/your-repo/aws-systems-manager-setup/main/2-cli-script-v9.sh
chmod +x 2-cli-script-v9.sh
./2-cli-script-v9.sh
```

The script will:
- Create the necessary IAM policy and role
- Configure Systems Manager with Host Management features
- Verify the setup
- Offer to clean up resources when complete

If you prefer to understand each step or customize the setup, continue with Option 2 for manual configuration.

## Option 2: Manual step-by-step setup

## Create IAM permissions for Systems Manager

To set up Systems Manager, you first need to create an IAM policy that grants the necessary permissions for onboarding and configuration.

**Create an IAM policy for Systems Manager onboarding**

The following command creates a new IAM policy that grants permissions to set up and configure Systems Manager.

```bash
cat > ssm-onboarding-policy.json << 'EOF'
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "QuickSetupActions",
       "Effect": "Allow",
       "Action": [
         "ssm-quicksetup:*"
       ],
       "Resource": "*"
     },
     {
       "Sid": "SsmReadOnly",
       "Effect": "Allow",
       "Action": [
         "ssm:DescribeAutomationExecutions",
         "ssm:GetAutomationExecution",
         "ssm:ListAssociations",
         "ssm:DescribeAssociation",
         "ssm:ListDocuments",
         "ssm:ListResourceDataSync",
         "ssm:DescribePatchBaselines",
         "ssm:GetPatchBaseline",
         "ssm:DescribeMaintenanceWindows",
         "ssm:DescribeMaintenanceWindowTasks"
       ],
       "Resource": "*"
     },
     {
       "Sid": "SsmDocument",
       "Effect": "Allow",
       "Action": [
         "ssm:GetDocument",
         "ssm:DescribeDocument"
       ],
       "Resource": [
         "arn:aws:ssm:*:*:document/AWSQuickSetupType-*",
         "arn:aws:ssm:*:*:document/AWS-EnableExplorer"
       ]
     },
     {
       "Sid": "SsmEnableExplorer",
       "Effect": "Allow",
       "Action": "ssm:StartAutomationExecution",
       "Resource": "arn:aws:ssm:*:*:automation-definition/AWS-EnableExplorer:*"
     },
     {
       "Sid": "SsmExplorerRds",
       "Effect": "Allow",
       "Action": [
         "ssm:GetOpsSummary",
         "ssm:CreateResourceDataSync",
         "ssm:UpdateResourceDataSync"
       ],
       "Resource": "arn:aws:ssm:*:*:resource-data-sync/AWS-QuickSetup-*"
     },
     {
       "Sid": "OrgsReadOnly",
       "Effect": "Allow",
       "Action": [
         "organizations:DescribeAccount",
         "organizations:DescribeOrganization",
         "organizations:ListDelegatedAdministrators",
         "organizations:ListRoots",
         "organizations:ListParents",
         "organizations:ListOrganizationalUnitsForParent",
         "organizations:DescribeOrganizationalUnit",
         "organizations:ListAWSServiceAccessForOrganization"
       ],
       "Resource": "*"
     },
     {
       "Sid": "OrgsAdministration",
       "Effect": "Allow",
       "Action": [
         "organizations:EnableAWSServiceAccess",
         "organizations:RegisterDelegatedAdministrator",
         "organizations:DeregisterDelegatedAdministrator"
       ],
       "Resource": "*",
       "Condition": {
         "StringEquals": {
           "organizations:ServicePrincipal": [
             "ssm.amazonaws.com",
             "ssm-quicksetup.amazonaws.com",
             "member.org.stacksets.cloudformation.amazonaws.com",
             "resource-explorer-2.amazonaws.com"
           ]
         }
       }
     },
     {
       "Sid": "CfnReadOnly",
       "Effect": "Allow",
       "Action": [
         "cloudformation:ListStacks",
         "cloudformation:DescribeStacks",
         "cloudformation:ListStackSets",
         "cloudformation:DescribeOrganizationsAccess"
       ],
       "Resource": "*"
     },
     {
       "Sid": "OrgCfnAccess",
       "Effect": "Allow",
       "Action": [
         "cloudformation:ActivateOrganizationsAccess"
       ],
       "Resource": "*"
     },
     {
       "Sid": "CfnStackActions",
       "Effect": "Allow",
       "Action": [
         "cloudformation:CreateStack",
         "cloudformation:DeleteStack",
         "cloudformation:DescribeStackResources",
         "cloudformation:DescribeStackEvents",
         "cloudformation:GetTemplate",
         "cloudformation:RollbackStack",
         "cloudformation:TagResource",
         "cloudformation:UntagResource",
         "cloudformation:UpdateStack"
       ],
       "Resource": [
         "arn:aws:cloudformation:*:*:stack/StackSet-AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:stack/AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:type/resource/*"
       ]
     },
     {
       "Sid": "CfnStackSetActions",
       "Effect": "Allow",
       "Action": [
         "cloudformation:CreateStackInstances",
         "cloudformation:CreateStackSet",
         "cloudformation:DeleteStackInstances",
         "cloudformation:DeleteStackSet",
         "cloudformation:DescribeStackInstance",
         "cloudformation:DetectStackSetDrift",
         "cloudformation:ListStackInstanceResourceDrifts",
         "cloudformation:DescribeStackSet",
         "cloudformation:DescribeStackSetOperation",
         "cloudformation:ListStackInstances",
         "cloudformation:ListStackSetOperations",
         "cloudformation:ListStackSetOperationResults",
         "cloudformation:TagResource",
         "cloudformation:UntagResource",
         "cloudformation:UpdateStackSet"
       ],
       "Resource": [
         "arn:aws:cloudformation:*:*:stackset/AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:type/resource/*",
         "arn:aws:cloudformation:*:*:stackset-target/AWS-QuickSetup-*:*"
       ]
     },
     {
       "Sid": "ValidationReadonlyActions",
       "Effect": "Allow",
       "Action": [
         "iam:ListRoles",
         "iam:GetRole"
       ],
       "Resource": "*"
     },
     {
       "Sid": "IamRolesMgmt",
       "Effect": "Allow",
       "Action": [
         "iam:CreateRole",
         "iam:DeleteRole",
         "iam:GetRole",
         "iam:AttachRolePolicy",
         "iam:DetachRolePolicy",
         "iam:GetRolePolicy",
         "iam:ListRolePolicies"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ]
     },
     {
       "Sid": "IamPassRole",
       "Effect": "Allow",
       "Action": [
         "iam:PassRole"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ],
       "Condition": {
         "StringEquals": {
           "iam:PassedToService": [
             "ssm.amazonaws.com",
             "ssm-quicksetup.amazonaws.com",
             "cloudformation.amazonaws.com"
           ]
         }
       }
     },
     {
       "Sid": "IamRolesPoliciesMgmt",
       "Effect": "Allow",
       "Action": [
         "iam:AttachRolePolicy",
         "iam:DetachRolePolicy"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ],
       "Condition": {
         "ArnEquals": {
           "iam:PolicyARN": [
             "arn:aws:iam::aws:policy/AWSSystemsManagerEnableExplorerExecutionPolicy",
             "arn:aws:iam::aws:policy/AWSQuickSetupSSMDeploymentRolePolicy"
           ]
         }
       }
     },
     {
       "Sid": "CfnStackSetsSLR",
       "Effect": "Allow",
       "Action": [
         "iam:CreateServiceLinkedRole"
       ],
       "Resource": [
         "arn:aws:iam::*:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin",
         "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM",
         "arn:aws:iam::*:role/aws-service-role/accountdiscovery.ssm.amazonaws.com/AWSServiceRoleForAmazonSSM_AccountDiscovery",
         "arn:aws:iam::*:role/aws-service-role/ssm-quicksetup.amazonaws.com/AWSServiceRoleForSSMQuickSetup",
         "arn:aws:iam::*:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
       ]
     }
   ]
}
EOF

aws iam create-policy --policy-name SSMOnboardingPolicy --policy-document file://ssm-onboarding-policy.json
```

The output will include the ARN of the newly created policy, which you'll need for the next step.

```json
{
    "Policy": {
        "PolicyName": "SSMOnboardingPolicy",
        "PolicyId": "ANPAYEWAPUR5OHLH7QQJQ",
        "Arn": "arn:aws:iam::123456789012:policy/SSMOnboardingPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2025-01-13T20:44:16Z",
        "UpdateDate": "2025-01-13T20:44:16Z"
    }
}
```

This policy grants the necessary permissions to set up and configure Systems Manager, including access to Quick Setup, CloudFormation, IAM roles, and AWS Organizations resources.

## Create an IAM role for Systems Manager

After creating the policy, you need to create an IAM role that Systems Manager can use to perform operations on your behalf.

**Get your account ID**

First, get your AWS account ID, which you'll need for the role configuration:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"
```

**Create a trust policy for the role**

Create a trust policy that allows Systems Manager services and your account to assume the role:

```bash
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ssm.amazonaws.com",
                    "ssm-quicksetup.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT_ID:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
```

**Create the IAM role**

Now create the IAM role using the trust policy:

```bash
ROLE_NAME="SSMTutorialRole-$(openssl rand -hex 4)"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json --description "Role for Systems Manager tutorial"
```

The output will include the ARN of the newly created role:

```json
{
    "Role": {
        "Path": "/",
        "RoleName": "SSMTutorialRole-a1b2c3d4",
        "RoleId": "AROAYEWAPUR5OHLH7QQJQ",
        "Arn": "arn:aws:iam::123456789012:role/SSMTutorialRole-a1b2c3d4",
        "CreateDate": "2025-01-13T20:44:16Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": [
                            "ssm.amazonaws.com",
                            "ssm-quicksetup.amazonaws.com"
                        ]
                    },
                    "Action": "sts:AssumeRole"
                },
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::123456789012:root"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

**Attach the policy to the role**

Now attach the Systems Manager onboarding policy to the role:

```bash
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/SSMOnboardingPolicy
```

After creating and configuring the role, it will have the necessary permissions for Systems Manager to set up and manage your resources.

## Configure Systems Manager

Now that you have the necessary permissions, you can configure Systems Manager for your account and region.

**Get your account ID and region**

First, get your AWS account ID and current region, which you'll need for the configuration:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CURRENT_REGION=$(aws configure get region)

echo "Account ID: $ACCOUNT_ID"
echo "Current Region: $CURRENT_REGION"
```

The output will show your 12-digit AWS account ID and the configured region:

```
Account ID: 123456789012
Current Region: us-east-1
```

**Create the Systems Manager configuration**

Create a configuration file for Systems Manager Host Management with the desired settings:

```bash
CONFIG_NAME="SSMSetup-$(openssl rand -hex 4)"

cat > ssm-config.json << EOF
[
  {
    "Type": "AWSQuickSetupType-SSMHostMgmt",
    "Parameters": {
      "UpdateSSMAgent": "true",
      "CollectInventory": "true",
      "ScanInstances": "true",
      "InstallCloudWatchAgent": "false",
      "UpdateCloudWatchAgent": "false",
      "IsPolicyAttachAllowed": "true",
      "TargetAccounts": ["$ACCOUNT_ID"],
      "TargetRegions": ["$CURRENT_REGION"],
      "TargetOrganizationalUnits": []
    }
  }
]
EOF
```

**Note:** This tutorial uses the `AWSQuickSetupType-SSMHostMgmt` configuration type, which is the recommended approach for setting up Systems Manager Host Management. This type provides better control over individual features and is optimized for single-account deployments.

This configuration enables the following features:

- **UpdateSSMAgent**: Enables automatic updates of the SSM Agent on your managed nodes
- **CollectInventory**: Enables Systems Manager to collect metadata from your nodes, including AWS components, applications, node details, and network configuration
- **ScanInstances**: Enables scanning of instances for compliance and security assessments
- **InstallCloudWatchAgent**: Set to false to avoid installing CloudWatch Agent (optional feature)
- **UpdateCloudWatchAgent**: Set to false to avoid automatic CloudWatch Agent updates
- **IsPolicyAttachAllowed**: Allows Systems Manager to attach necessary policies to EC2 instances automatically
- **TargetAccounts**: Specifies your account ID as the target for the configuration
- **TargetRegions**: Specifies the current region as the target region
- **TargetOrganizationalUnits**: Empty array since this is for a single account setup

Now, create the configuration manager using the AWS CLI:

```bash
aws ssm-quicksetup create-configuration-manager --name "$CONFIG_NAME" --configuration-definitions file://ssm-config.json --region $CURRENT_REGION
```

The output will include the ARN of the newly created configuration manager:

```json
{
    "ManagerArn": "arn:aws:ssm-quicksetup:us-east-1:123456789012:configuration-manager/abcd1234-5678-90ab-cdef-11223344xmpl"
}
```

## Verify the setup

After creating the configuration, you should verify that it was set up correctly.

**Check the configuration manager status**

Use the following command to check the status of your configuration manager, replacing the ARN with the one from your output:

```bash
MANAGER_ARN="arn:aws:ssm-quicksetup:us-east-1:123456789012:configuration-manager/abcd1234-5678-90ab-cdef-11223344xmpl"
aws ssm-quicksetup get-configuration-manager --manager-arn $MANAGER_ARN --region $CURRENT_REGION
```

The output will provide detailed information about your configuration:

```json
{
    "ConfigurationDefinitions": [
        {
            "Id": "abcd1234-5678-90ab-cdef-11223344xmpl",
            "Parameters": {
                "enableDefaultHostManagementConfiguration": "true",
                "driftRemediationFrequency": "7",
                "enableInventoryCollection": "true",
                "inventoryCollectionFrequency": "24",
                "enableAutomaticAgentUpdates": "true",
                "agentUpdateFrequency": "14",
                "targetAccounts": "123456789012"
            },
            "Type": "AWSQuickSetupType-SSM",
            "TypeVersion": "2.0"
        }
    ],
    "CreatedAt": "2025-01-13T20:44:16.000Z",
    "LastModifiedAt": "2025-01-13T20:44:16.000Z",
    "ManagerArn": "arn:aws:ssm-quicksetup:us-east-1:123456789012:configuration-manager/abcd1234-5678-90ab-cdef-11223344xmpl",
    "Name": "SSMSetup",
    "StatusSummaries": [
        {
            "LastUpdatedAt": "2025-01-13T20:44:16.000Z",
            "Status": "SUCCESS",
            "StatusType": "DEPLOYMENT"
        }
    ]
}
```

**List State Manager associations**

You can also verify that the necessary State Manager associations were created:

```bash
aws ssm list-associations
```

The output will show the associations created by Systems Manager:

```json
{
    "Associations": [
        {
            "Name": "AWS-GatherSoftwareInventory",
            "InstanceId": "",
            "AssociationId": "abcd1234-5678-90ab-cdef-11223344xmpl",
            "AssociationVersion": "1",
            "DocumentVersion": "1",
            "Targets": [
                {
                    "Key": "InstanceIds",
                    "Values": [
                        "*"
                    ]
                }
            ],
            "LastExecutionDate": "2025-01-13T20:44:16.000Z",
            "Overview": {
                "Status": "Success",
                "AssociationStatusAggregatedCount": {
                    "Success": 1
                }
            },
            "ScheduleExpression": "rate(30 minutes)"
        },
        {
            "Name": "AWS-UpdateSSMAgent",
            "InstanceId": "",
            "AssociationId": "efgh5678-90ab-cdef-1122-3344xmpl5566",
            "AssociationVersion": "1",
            "DocumentVersion": "1",
            "Targets": [
                {
                    "Key": "InstanceIds",
                    "Values": [
                        "*"
                    ]
                }
            ],
            "LastExecutionDate": "2025-01-13T20:44:16.000Z",
            "Overview": {
                "Status": "Success",
                "AssociationStatusAggregatedCount": {
                    "Success": 1
                }
            },
            "ScheduleExpression": "rate(14 days)"
        }
    ]
}
```

## Troubleshooting

If you encounter issues during the setup process, here are some common problems and solutions:

**Issue: Permission denied errors**
- Make sure the IAM user or role you're using has the SSMOnboardingPolicy attached
- Verify that the policy was created correctly with all the necessary permissions
- Check if your AWS CLI is configured with the correct credentials

**Issue: Configuration manager creation fails**
- Ensure the JSON format in the configuration file is correct
- Verify that you're specifying the correct region in the command
- Check that the account ID in the configuration is correct
- Make sure you're using the correct configuration type (`AWSQuickSetupType-SSMHostMgmt`)

**Issue: State Manager associations not created**
- Wait a few minutes as it can take time for associations to be created
- Check the CloudFormation stacks in the AWS Management Console to see if there are any deployment errors
- Verify that the configuration manager was created successfully

## Clean up resources

If you need to clean up the resources created in this tutorial, follow these steps.

**Delete the configuration manager**

To delete the Systems Manager configuration manager:

```bash
aws ssm-quicksetup delete-configuration-manager --manager-arn $MANAGER_ARN --region $CURRENT_REGION
```

**Detach and delete the IAM policy**

First, detach the policy from the IAM role:

```bash
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/SSMOnboardingPolicy
```

**Delete the IAM role**

Delete the IAM role:

```bash
aws iam delete-role --role-name $ROLE_NAME
```

**Delete the IAM policy**

Finally, delete the policy:

```bash
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/SSMOnboardingPolicy
```

## Going to production

This tutorial is designed to help you learn how to set up AWS Systems Manager in a test environment. When moving to a production environment, consider the following best practices:

**Security best practices:**
- Use VPC endpoints for Systems Manager to keep traffic within your VPC
- Implement least privilege by scoping down IAM permissions to only what's needed
- Use AWS KMS to encrypt Systems Manager parameters and outputs
- Regularly audit and rotate credentials
- Consider using temporary credentials instead of long-term access keys

**Architecture best practices:**
- For multi-account environments, use AWS Organizations and delegated administration
- For cross-region management, set up Systems Manager in each region you operate in
- Implement monitoring and alerting for Systems Manager operations using CloudWatch
- Consider backup and disaster recovery strategies for your Systems Manager resources
- Use tagging for resource organization and cost allocation

For more information on security and architecture best practices, refer to:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Systems Manager Security Best Practices](https://docs.aws.amazon.com/systems-manager/latest/userguide/security-best-practices.html)

## Next steps

Now that you've set up AWS Systems Manager, you can explore its various features and capabilities:

1. **Fleet Manager** - [Manage your EC2 instances and on-premises servers](https://docs.aws.amazon.com/systems-manager/latest/userguide/fleet-manager.html) from a unified interface.
2. **Patch Manager** - [Automate the process of patching your managed nodes](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager.html) with security updates.
3. **State Manager** - [Maintain your instances in a defined state](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state.html) using associations.
4. **Inventory** - [Collect metadata from your managed nodes](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-inventory.html) to understand your system configurations.
5. **Session Manager** - [Manage your EC2 instances through an interactive browser-based shell](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) without the need to open inbound ports.

For more information about available AWS CLI commands for Systems Manager, see the [AWS CLI Command Reference for Systems Manager](https://docs.aws.amazon.com/cli/latest/reference/ssm/index.html) and [AWS CLI Command Reference for Systems Manager Quick Setup](https://docs.aws.amazon.com/cli/latest/reference/ssm-quicksetup/index.html).
