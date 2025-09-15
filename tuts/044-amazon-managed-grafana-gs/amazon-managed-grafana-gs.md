# Creating an Amazon Managed Grafana workspace using the AWS CLI

This tutorial guides you through creating and configuring an Amazon Managed Grafana workspace using the AWS Command Line Interface (AWS CLI). Amazon Managed Grafana is a fully managed service that makes it easy to deploy, operate, and scale Grafana, a popular open-source analytics platform.

## Topics

- [Prerequisites](#prerequisites)
- [Create an IAM role for your workspace](#create-an-iam-role-for-your-workspace)
- [Create a Grafana workspace](#create-a-grafana-workspace)
- [Configure authentication](#configure-authentication)
- [Configure optional settings](#configure-optional-settings)
- [Access your Grafana workspace](#access-your-grafana-workspace)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. The necessary permissions to create and manage Amazon Managed Grafana workspaces and IAM roles. At minimum, you need the **AWSGrafanaAccountAdministrator** policy attached to your IAM principal.
4. If you plan to use IAM Identity Center for authentication, you also need the **AWSSSOMemberAccountAdministrator** and **AWSSSODirectoryAdministrator** policies.

### Cost considerations

Amazon Managed Grafana is priced based on active users per workspace per month:
- Standard Edition: $9.00 per active user per workspace per month
- Enterprise Edition: $19.00 per active user per workspace per month

For this tutorial with 1 admin user, the cost would be approximately $0.0125 per hour (prorated from the monthly rate). If you follow the cleanup instructions promptly after completing the tutorial, the actual cost incurred would be minimal.

Additional costs may apply if you use the workspace to query data from other AWS services like CloudWatch, Prometheus, or X-Ray, or if you enable VPC connectivity.

## Create an IAM role for your workspace

Before creating a Grafana workspace, you need to create an IAM role that grants permissions to the AWS resources that the workspace will access. This role allows Amazon Managed Grafana to read data from services like CloudWatch, Prometheus, and X-Ray.

**Create a trust policy document**

First, create a trust policy document that allows the Grafana service to assume the role:

```
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "grafana.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This trust policy enables the Amazon Managed Grafana service to assume this role when accessing AWS resources on behalf of your workspace.

**Create the IAM role**

Now, create the IAM role using the trust policy:

```
aws iam create-role \
  --role-name GrafanaWorkspaceRole \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for Amazon Managed Grafana workspace"
```

The command returns details about the newly created role, including its ARN, which you'll need when creating the workspace:

```
{
    "Role": {
        "Path": "/",
        "RoleName": "GrafanaWorkspaceRole",
        "RoleId": "AROAEXAMPLEID",
        "Arn": "arn:aws:iam::123456789012:role/GrafanaWorkspaceRole",
        "CreateDate": "2025-01-13T12:00:00Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "grafana.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

**Create and attach a policy for CloudWatch access**

Create a policy that grants permissions to access CloudWatch metrics:

```
cat > cloudwatch-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:GetMetricData"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name GrafanaCloudWatchPolicy \
  --policy-document file://cloudwatch-policy.json
```

The command returns details about the newly created policy:

```
{
    "Policy": {
        "PolicyName": "GrafanaCloudWatchPolicy",
        "PolicyId": "ANPAEXAMPLEID",
        "Arn": "arn:aws:iam::123456789012:policy/GrafanaCloudWatchPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2025-01-13T12:00:00Z",
        "UpdateDate": "2025-01-13T12:00:00Z"
    }
}
```

After creating the policy, attach it to the role:

```
aws iam attach-role-policy \
  --role-name GrafanaWorkspaceRole \
  --policy-arn arn:aws:iam::123456789012:policy/GrafanaCloudWatchPolicy
```

Replace `123456789012` with your AWS account ID. This policy allows your Grafana workspace to read CloudWatch metrics and alarms.

## Create a Grafana workspace

Now that you have created the necessary IAM role, you can create your Amazon Managed Grafana workspace.

**Create the workspace**

Use the following command to create a new workspace:

```
aws grafana create-workspace \
  --workspace-name MyGrafanaWorkspace \
  --authentication-providers "SAML" \
  --permission-type "CUSTOMER_MANAGED" \
  --account-access-type "CURRENT_ACCOUNT" \
  --workspace-role-arn "arn:aws:iam::123456789012:role/GrafanaWorkspaceRole" \
  --workspace-data-sources "CLOUDWATCH" "PROMETHEUS" "XRAY" \
  --grafana-version "10.4" \
  --tags Environment=Development
```

Replace `123456789012` with your AWS account ID. This command creates a workspace with the following configuration:

- Name: MyGrafanaWorkspace
- Authentication: SAML (Security Assertion Markup Language)
- Permission type: Customer managed (you manage the IAM roles and permissions)
- Account access: Current account only
- Data sources: CloudWatch, Prometheus, and X-Ray
- Grafana version: 10.4

The response includes details about the workspace:

```
{
    "workspace": {
        "id": "g-abcd1234",
        "name": "MyGrafanaWorkspace",
        "accountAccessType": "CURRENT_ACCOUNT",
        "authentication": {
            "providers": [
                "SAML"
            ],
            "samlConfigurationStatus": "NOT_CONFIGURED"
        },
        "created": 1673596800.000,
        "dataSources": [
            "CLOUDWATCH",
            "PROMETHEUS",
            "XRAY"
        ],
        "description": "",
        "grafanaVersion": "10.4",
        "permissionType": "CUSTOMER_MANAGED",
        "status": "CREATING",
        "tags": {
            "Environment": "Development"
        },
        "workspaceRoleArn": "arn:aws:iam::123456789012:role/GrafanaWorkspaceRole"
    }
}
```

Note the workspace ID (e.g., `g-abcd1234`), as you'll need it for subsequent operations.

**Check workspace status**

After creating the workspace, check its status to ensure it becomes active:

```
aws grafana describe-workspace --workspace-id g-abcd1234
```

Replace `g-abcd1234` with your workspace ID. The workspace status will initially be `CREATING`. Wait until the status changes to `ACTIVE` before proceeding:

```
{
    "workspace": {
        "id": "g-abcd1234",
        "name": "MyGrafanaWorkspace",
        "accountAccessType": "CURRENT_ACCOUNT",
        "authentication": {
            "providers": [
                "SAML"
            ],
            "samlConfigurationStatus": "NOT_CONFIGURED"
        },
        "created": 1673596800.000,
        "dataSources": [
            "CLOUDWATCH",
            "PROMETHEUS",
            "XRAY"
        ],
        "description": "",
        "endpoint": "g-abcd1234.grafana-workspace.us-east-1.amazonaws.com",
        "grafanaVersion": "10.4",
        "permissionType": "CUSTOMER_MANAGED",
        "status": "ACTIVE",
        "tags": {
            "Environment": "Development"
        },
        "workspaceRoleArn": "arn:aws:iam::123456789012:role/GrafanaWorkspaceRole"
    }
}
```

## Configure authentication

Amazon Managed Grafana supports two authentication methods: SAML and IAM Identity Center. This section covers how to configure each method.

**Configure SAML authentication**

If you selected SAML as your authentication provider, you need to configure it:

```
aws grafana update-workspace-authentication \
  --workspace-id g-abcd1234 \
  --authentication-providers "SAML" \
  --saml-configuration '{
    "idpMetadata": {
      "url": "https://your-idp-metadata-url"
    },
    "assertionAttributes": {
      "role": "role",
      "name": "name",
      "login": "login",
      "email": "email"
    },
    "roleValues": {
      "admin": ["admin-role"]
    }
  }'
```

Replace `g-abcd1234` with your workspace ID and `https://your-idp-metadata-url` with the URL of your identity provider's metadata. This configuration maps SAML attributes to Grafana user properties and assigns admin roles.

The response confirms the authentication configuration:

```
{
    "authentication": {
        "providers": [
            "SAML"
        ],
        "samlConfigurationStatus": "CONFIGURED"
    }
}
```

**Configure IAM Identity Center authentication**

If you're using IAM Identity Center, first list the available users:

```
aws identitystore list-users --identity-store-id d-abcd1234
```

Replace `d-abcd1234` with your Identity Store ID. The command returns a list of users:

```
{
    "Users": [
        {
            "UserId": "abcd1234-efgh-5678-ijkl-9012mnop3456",
            "UserName": "jdoe",
            "Name": {
                "Formatted": "John Doe",
                "FamilyName": "Doe",
                "GivenName": "John"
            },
            "DisplayName": "John Doe",
            "Emails": [
                {
                    "Value": "jdoe@example.com",
                    "Type": "Work",
                    "Primary": true
                }
            ]
        }
    ]
}
```

Then, assign a user as an admin:

```
aws grafana update-permissions \
  --workspace-id g-abcd1234 \
  --update-instruction-batch '[{
    "action": "ADD",
    "role": "ADMIN",
    "users": [{
      "id": "abcd1234-efgh-5678-ijkl-9012mnop3456",
      "type": "SSO_USER"
    }]
  }]'
```

Replace `g-abcd1234` with your workspace ID and `abcd1234-efgh-5678-ijkl-9012mnop3456` with the user ID you want to assign as admin.

## Configure optional settings

Amazon Managed Grafana offers several optional configurations to enhance your workspace.

**Enable network access control**

To restrict access to your workspace to specific IP addresses or VPC endpoints:

```
aws grafana update-workspace \
  --workspace-id g-abcd1234 \
  --network-access-control '{
    "prefixListIds": ["pl-abcd1234"],
    "vpceIds": ["vpce-abcd1234"]
  }'
```

Replace `g-abcd1234` with your workspace ID, `pl-abcd1234` with your prefix list ID, and `vpce-abcd1234` with your VPC endpoint ID. This configuration restricts access to the specified IP ranges and VPC endpoints.

**Configure VPC connection**

To connect your workspace to resources in a VPC:

```
aws grafana update-workspace \
  --workspace-id g-abcd1234 \
  --vpc-configuration '{
    "securityGroupIds": ["sg-abcd1234"],
    "subnetIds": ["subnet-abcd1234", "subnet-efgh5678"]
  }'
```

Replace `g-abcd1234` with your workspace ID, `sg-abcd1234` with your security group ID, and the subnet IDs with your subnet IDs. This allows your workspace to connect to data sources in your VPC.

**Enable Grafana alerting**

To enable Grafana's unified alerting feature:

```
aws grafana update-workspace-configuration \
  --workspace-id g-abcd1234 \
  --configuration '{
    "unifiedAlerting": {
      "enabled": true
    }
  }'
```

Replace `g-abcd1234` with your workspace ID. This enables Grafana's unified alerting system, which allows you to view and manage alerts from multiple sources in one interface.

**Enable plugin management**

To allow Grafana administrators to install and manage plugins:

```
aws grafana update-workspace-configuration \
  --workspace-id g-abcd1234 \
  --configuration '{
    "pluginAdminEnabled": true
  }'
```

Replace `g-abcd1234` with your workspace ID. This allows workspace administrators to install, update, and remove plugins.

## Access your Grafana workspace

Once your workspace is active and configured, you can access it using the URL provided in the workspace details.

**Get the workspace URL**

```
aws grafana describe-workspace --workspace-id g-abcd1234
```

Replace `g-abcd1234` with your workspace ID. Look for the `endpoint` value in the output, which is your Grafana workspace URL.

**Sign in to your workspace**

Open the workspace URL in your web browser. Depending on your authentication method:

- For SAML: Click "Sign in with SAML" and enter your credentials in your identity provider's login page.
- For IAM Identity Center: Click "Sign in with AWS IAM Identity Center" and enter your email address and password.

Once signed in, you can start adding data sources, creating dashboards, and visualizing your data.

## Clean up resources

When you no longer need your Grafana workspace, you should delete it to avoid incurring charges.

**Delete the workspace**

```
aws grafana delete-workspace --workspace-id g-abcd1234
```

Replace `g-abcd1234` with your workspace ID. This command deletes your Grafana workspace.

Wait for the workspace to be deleted before proceeding with the next steps. You can check the status by running:

```
aws grafana describe-workspace --workspace-id g-abcd1234
```

If the workspace has been deleted, you'll receive an error message indicating that the workspace doesn't exist.

**Clean up IAM resources**

After deleting the workspace, clean up the IAM resources:

```
aws iam detach-role-policy \
  --role-name GrafanaWorkspaceRole \
  --policy-arn arn:aws:iam::123456789012:policy/GrafanaCloudWatchPolicy

aws iam delete-policy \
  --policy-arn arn:aws:iam::123456789012:policy/GrafanaCloudWatchPolicy

aws iam delete-role \
  --role-name GrafanaWorkspaceRole
```

Replace `123456789012` with your AWS account ID. These commands detach and delete the policy, then delete the role.

**Clean up JSON files**

Finally, remove the JSON files created during the tutorial:

```
rm trust-policy.json cloudwatch-policy.json
```

## Going to production

This tutorial is designed to help you learn how to use the Amazon Managed Grafana API through the AWS CLI. When moving to a production environment, consider the following security and architecture best practices:

### Security considerations

1. **Least privilege access**: The CloudWatch policy in this tutorial uses a wildcard resource (`"Resource": "*"`). In production, restrict access to only the specific resources needed.

2. **Network access control**: Implement network access control to restrict access to your workspace from specific IP ranges or VPC endpoints.

3. **Encryption**: Configure encryption settings for sensitive data in your Grafana workspace.

4. **Monitoring and auditing**: Set up AWS CloudTrail to monitor API calls to your Grafana workspace for security auditing.

### Architecture considerations

1. **High availability**: Consider implementing backup strategies for your workspace configurations.

2. **Multi-workspace architecture**: For larger organizations, design a multi-workspace architecture to separate concerns between teams or departments.

3. **Authentication at scale**: Implement group-based access control for managing large numbers of users.

4. **Cost management**: Monitor usage costs and implement strategies to optimize costs, such as managing the number of active users.

For more information on AWS security and architecture best practices, refer to:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html)
- [Amazon Managed Grafana Security](https://docs.aws.amazon.com/grafana/latest/userguide/security.html)

## Next steps

Now that you've created an Amazon Managed Grafana workspace, explore these additional features:

1. [Add data sources to your workspace](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-data-sources.html) to start visualizing your data.
2. [Create dashboards](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-dashboards.html) to monitor your applications and infrastructure.
3. [Set up alerts](https://docs.aws.amazon.com/grafana/latest/userguide/alerts-overview.html) to get notified when metrics cross thresholds.
4. [Configure user access](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-manage-users.html) to control who can view and edit your dashboards.
5. [Connect to Amazon VPC](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-configure-vpc.html) to access data sources in your private network.
