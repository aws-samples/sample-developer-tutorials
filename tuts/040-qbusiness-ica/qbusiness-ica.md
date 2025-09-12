# Creating an Amazon Q Business application using the AWS CLI

This tutorial guides you through the process of creating an Amazon Q Business application using the AWS Command Line Interface (AWS CLI). Amazon Q Business is a generative AI-powered assistant that helps your employees find information and complete tasks within your organization.

By the end of this tutorial, you'll have a fully functional Amazon Q Business application with user access configured through AWS IAM Identity Center.

## Prerequisites

Before you begin this tutorial, make sure you have:

- An AWS account with permissions to create and manage Amazon Q Business resources, IAM Identity Center, IAM roles, and policies.
- The AWS CLI installed and configured with appropriate credentials. For information about installing the AWS CLI, see [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- Basic familiarity with AWS CLI commands and JSON syntax.
- Approximately 30 minutes to complete the tutorial.

### Cost considerations

This tutorial creates resources that incur charges to your AWS account:

- Amazon Q Business Pro user subscription: $40 per user per month
- Amazon Q Business Lite user subscription (optional): $20 per user per month

The total cost for running the resources in this tutorial for one hour is approximately $0.056 (for one Pro user) or $0.084 (if you also create a group with a Lite subscription). To avoid ongoing charges, follow the cleanup steps at the end of the tutorial.

## Step 1: Set up IAM Identity Center

Amazon Q Business uses IAM Identity Center for user management. In this step, you'll check if you have an IAM Identity Center instance and create one if needed.

First, check if you already have an IAM Identity Center instance. Replace `us-east-1` with the AWS Region where your IAM Identity Center instance is located.

```bash
aws sso-admin list-instances --region us-east-1 --query 'Instances[0].InstanceArn' --output text
```

If the command returns `None` or an empty result, you need to create an IAM Identity Center instance. Replace `us-east-1` with the AWS Region where you want to create your IAM Identity Center instance.

```bash
aws sso-admin create-instance --region us-east-1 --name "QBusinessIdentityCenter-abcd1234" --query 'InstanceArn' --output text
```

This command creates an IAM Identity Center instance and returns its Amazon Resource Name (ARN). Save this ARN as you'll need it in subsequent steps.

After creating the instance, wait for it to become available (approximately 30 seconds).

## Step 2: Create IAM roles and policies

Amazon Q Business requires IAM roles and policies to function properly. In this step, you'll create the necessary IAM resources.

First, create a trust policy file that allows Amazon Q Business to assume the role:

Note: For this tutorial, replace "123456789012" with your AWS account ID. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
cat > qbusiness-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AmazonQApplicationPermission",
      "Effect": "Allow",
      "Principal": {
        "Service": "qbusiness.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "123456789012"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:qbusiness:us-east-1:123456789012:application/*"
        }
      }
    }
  ]
}
EOF
```

Next, create a permissions policy file that defines what actions the role can perform.

Note: For this tutorial, replace "123456789012" with your AWS account number. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
cat > qbusiness-permissions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AmazonQApplicationPutMetricDataPermission",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "AWS/QBusiness"
        }
      }
    },
    {
      "Sid": "AmazonQApplicationDescribeLogGroupsPermission",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AmazonQApplicationCreateLogGroupPermission",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:123456789012:log-group:/aws/qbusiness/*"
      ]
    },
    {
      "Sid": "AmazonQApplicationLogStreamPermission",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogStreams",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:123456789012:log-group:/aws/qbusiness/*:log-stream:*"
      ]
    }
  ]
}
EOF
```

Now, create the IAM role using the trust policy. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam create-role \
  --region us-east-1 \
  --role-name "QBusinessServiceRole-abcd1234" \
  --assume-role-policy-document file://qbusiness-trust-policy.json \
  --query 'Role.Arn' \
  --output text
```

Create an IAM policy using the permissions policy file. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam create-policy \
  --region us-east-1 \
  --policy-name "QBusinessPolicy-abcd1234" \
  --policy-document file://qbusiness-permissions-policy.json \
  --query 'Policy.Arn' \
  --output text
```

Attach the policy to the role. Replace "123456789012" with your AWS account number. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam attach-role-policy \
  --region us-east-1 \
  --role-name "QBusinessServiceRole-abcd1234" \
  --policy-arn "arn:aws:iam::123456789012:policy/QBusinessPolicy-abcd1234"
```

After creating the role and policy, wait for them to propagate (approximately 15 seconds).

## Step 3: Create a user in IAM Identity Center

Before creating the Amazon Q Business application, you need to set up a user in IAM Identity Center who will access the application.

First, get the Identity Store ID associated with your IAM Identity Center instance.

Replace "arn:aws:sso:::instance/ssoins-abcd1234xmpl" with the ARN of your IAM Identity Center instance. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.

```bash
aws sso-admin describe-instance \
  --region us-east-1 \
  --instance-arn "arn:aws:sso:::instance/ssoins-abcd1234xmpl" \
  --query 'IdentityStoreId' \
  --output text
```

Make a note of the Identity Store ID in the response. You'll use it in the following command.

Now, create a user in the Identity Store. Replace "d-abcd1234xmpl" with your actual Identity Store ID. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.
Note: In a production environment, use valid email addresses from your organization's domain instead of example.com.

```bash
aws identitystore create-user \
  --region us-east-1 \
  --identity-store-id "d-abcd1234xmpl" \
  --user-name "qbusiness-user-abcd1234" \
  --name '{"GivenName":"QBusiness","FamilyName":"User"}' \
  --emails '[{"Value":"qbusiness-user-abcd1234@example.com","Type":"Work","Primary":true}]' \
  --display-name "QBusiness Test User" \
  --query 'UserId' \
  --output text
```

This command creates a user in IAM Identity Center and returns the user ID. Save this ID as you'll need it in subsequent steps.



## Step 4: Create an Amazon Q Business application

Now you're ready to create the Amazon Q Business application.

Create the application using the following command. Replace "arn:aws:sso:::instance/ssoins-abcd1234xmpl" with your actual IAM Identity Center instance ARN. Replace "123456789012" with your AWS account number. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.

```bash
aws qbusiness create-application \
  --region us-east-1 \
  --display-name "MyQBusinessApp-abcd1234" \
  --identity-center-instance-arn "arn:aws:sso:::instance/ssoins-abcd1234xmpl" \
  --role-arn "arn:aws:iam::123456789012:role/QBusinessServiceRole-abcd1234" \
  --description "Amazon Q Business application created via CLI" \
  --attachments-configuration '{"attachmentsControlMode":"ENABLED"}' \
  --query 'applicationId' \
  --output text
```

This command creates an Amazon Q Business application and returns the application ID. Save this ID as you'll need it in subsequent steps.

After creating the application, wait for it to be fully provisioned (approximately 30 seconds).

Next, get the application ARN from IAM Identity Center. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.

```bash
aws sso-admin list-applications \
  --region us-east-1 \
  --instance-arn "arn:aws:sso:::instance/ssoins-abcd1234xmpl" \
  --query "Applications[?Name=='MyQBusinessApp-abcd1234'].ApplicationArn" \
  --output text
```

If the command doesn't return an ARN immediately, wait a few seconds and try again. The application may take some time to appear in IAM Identity Center.

## Step 5: Enable creator mode (LLM direct chat)

To allow users to chat directly with the LLM without creating an index, you need to enable creator mode. Replace "app-abcd1234xmpl" with your actual application ID from Step 4. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness update-chat-controls-configuration \
  --region us-east-1 \
  --application-id "app-abcd1234xmpl" \
  --creator-mode-configuration '{ "creatorModeControl": "ENABLED" }'
```



## Step 6: Assign the user to the application

Now that you have both the user and the application created, you need to assign the user to the application. Replace "arn:aws:sso::123456789012:application/ssoins-abcd1234xmpl/apl-abcd1234xmpl" with your application ARN. Replace "1234abcd-xmpl-5678-efgh-90ijklmnopqr" with the user ID that's returned in Step 3. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.

```bash
aws sso-admin create-application-assignment \
  --region us-east-1 \
  --application-arn "arn:aws:sso::123456789012:application/ssoins-abcd1234xmpl/apl-abcd1234xmpl" \
  --principal-id "1234abcd-xmpl-5678-efgh-90ijklmnopqr" \
  --principal-type USER
```

This command assigns the user to the Amazon Q Business application, allowing them to access it.

## Step 7: Create a user subscription

After assigning the user to the application, you need to create a subscription that determines their access level. Replace "app-abcd1234xmpl" with the application ID that's returned in Step 4. Replace "1234abcd-xmpl-5678-efgh-90ijklmnopqr" with the user ID that's returned in Step 3. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness create-subscription \
  --region us-east-1 \
  --application-id "app-abcd1234xmpl" \
  --principal user="1234abcd-xmpl-5678-efgh-90ijklmnopqr" \
  --type Q_BUSINESS \
  --query 'subscriptionId' \
  --output text
```

This command creates a full Q Business subscription for the user, giving them full access to the application's features.

## Step 8: Create a web experience (optional)

To provide a web interface for your Amazon Q Business application, you can create a web experience.

First, create a trust policy file for the web experience role. Replace "123456789012" with your AWS account number. Replace "app-abcd1234xmpl" with the Q Business application ID that's returned from Step 4. Replace "us-east-1" with the AWS Region of your Q Business application.

```bash
cat > qbusiness-web-trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "QBusinessTrustPolicy",
            "Effect": "Allow",
            "Principal": {
                "Service": "application.qbusiness.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:SetContext"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "123456789012"
                },
                "ArnEquals": {
                    "aws:SourceArn": "arn:aws:qbusiness:us-east-1:123456789012:application/app-abcd1234xmpl"
                }
            }
        }
    ]
}
EOF
```

Next, create a permissions policy file for the web experience. Replace "app-abcd1234xmpl" with your actual application ID that's returned in Step 4 and replace "123456789012" with your AWS account ID. Replace "us-east-1" with the AWS Region of your Q Business Application.

```bash
cat > qbusiness-web-permissions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "QBusinessConversationPermissions",
            "Effect": "Allow",
            "Action": [
                "qbusiness:Chat",
                "qbusiness:ChatSync",
                "qbusiness:ListMessages",
                "qbusiness:ListConversations",
                "qbusiness:PutFeedback",
                "qbusiness:DeleteConversation",
                "qbusiness:GetWebExperience",
                "qbusiness:GetApplication",
                "qbusiness:ListPlugins",
                "qbusiness:ListPluginActions",
                "qbusiness:GetChatControlsConfiguration",
                "qbusiness:ListRetrievers",
                "qbusiness:ListAttachments",
                "qbusiness:DeleteAttachment",
                "qbusiness:GetMedia"
            ],
            "Resource": "arn:aws:qbusiness:us-east-1:123456789012:application/app-abcd1234xmpl"
        },
        {
            "Sid": "QBusinessPluginDiscoveryPermissions",
            "Effect": "Allow",
            "Action": [
                "qbusiness:ListPluginTypeMetadata",
                "qbusiness:ListPluginTypeActions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "QBusinessRetrieverPermission",
            "Effect": "Allow",
            "Action": [
                "qbusiness:GetRetriever"
            ],
            "Resource": [
                "arn:aws:qbusiness:us-east-1:123456789012:application/app-abcd1234xmpl",
                "arn:aws:qbusiness:us-east-1:123456789012:application/app-abcd1234xmpl/retriever/*"
            ]
        },
        {
            "Sid": "QAppsResourceAgnosticPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:CreateQApp",
                "qapps:PredictQApp",
                "qapps:PredictProblemStatementFromConversation",
                "qapps:PredictQAppFromProblemStatement",
                "qapps:ListQApps",
                "qapps:ListLibraryItems",
                "qapps:CreateSubscriptionToken",
                "qapps:ListCategories"
            ],
            "Resource": "arn:aws:qbusiness:us-east-1:123456789012:application/app-abcd1234xmpl"
        },
        {
            "Sid": "QAppsAppUniversalPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:DisassociateQAppFromUser"
            ],
            "Resource": "arn:aws:qapps:us-east-1:123456789012:application/app-abcd1234xmpl/qapp/*"
        },
        {
            "Sid": "QAppsAppOwnerPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:GetQApp",
                "qapps:CopyQApp",
                "qapps:UpdateQApp",
                "qapps:DeleteQApp",
                "qapps:ImportDocument",
                "qapps:ImportDocumentToQApp",
                "qapps:CreateLibraryItem",
                "qapps:UpdateLibraryItem",
                "qapps:StartQAppSession",
                "qapps:DescribeQAppPermissions",
                "qapps:UpdateQAppPermissions",
                "qapps:CreatePresignedUrl"
            ],
            "Resource": "arn:aws:qapps:us-east-1:123456789012:application/app-abcd1234xmpl/qapp/*",
            "Condition": {
                "StringEqualsIgnoreCase": {
                    "qapps:UserIsAppOwner": "true"
                }
            }
        },
        {
            "Sid": "QAppsPublishedAppPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:GetQApp",
                "qapps:CopyQApp",
                "qapps:AssociateQAppWithUser",
                "qapps:GetLibraryItem",
                "qapps:CreateLibraryItemReview",
                "qapps:AssociateLibraryItemReview",
                "qapps:DisassociateLibraryItemReview",
                "qapps:StartQAppSession",
                "qapps:DescribeQAppPermissions"
            ],
            "Resource": "arn:aws:qapps:us-east-1:123456789012:application/app-abcd1234xmpl/qapp/*",
            "Condition": {
                "StringEqualsIgnoreCase": {
                    "qapps:AppIsPublished": "true"
                }
            }
        },
        {
            "Sid": "QAppsAppSessionModeratorPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:ImportDocument",
                "qapps:ImportDocumentToQAppSession",
                "qapps:GetQAppSession",
                "qapps:GetQAppSessionMetadata",
                "qapps:UpdateQAppSession",
                "qapps:UpdateQAppSessionMetadata",
                "qapps:StopQAppSession",
                "qapps:ListQAppSessionData",
                "qapps:ExportQAppSessionData",
                "qapps:CreatePresignedUrl"
            ],
            "Resource": "arn:aws:qapps:us-east-1:123456789012:application/app-abcd1234xmpl/qapp/*/session/*",
            "Condition": {
                "StringEqualsIgnoreCase": {
                    "qapps:UserIsSessionModerator": "true"
                }
            }
        },
        {
            "Sid": "QAppsSharedAppSessionPermissions",
            "Effect": "Allow",
            "Action": [
                "qapps:ImportDocument",
                "qapps:ImportDocumentToQAppSession",
                "qapps:GetQAppSession",
                "qapps:GetQAppSessionMetadata",
                "qapps:UpdateQAppSession",
                "qapps:ListQAppSessionData",
                "qapps:CreatePresignedUrl"
            ],
            "Resource": "arn:aws:qapps:us-east-1:123456789012:application/app-abcd1234xmpl/qapp/*/session/*",
            "Condition": {
                "StringEqualsIgnoreCase": {
                    "qapps:SessionIsShared": "true"
                }
            }
        },
        {
            "Sid": "QBusinessToQuickSightGenerateEmbedUrlInvocation",
            "Effect": "Allow",
            "Action": [
                "quicksight:GenerateEmbedUrlForRegisteredUserWithIdentity"
            ],
            "Resource": "*"
        }
    ]
}
EOF
```

Create the IAM role for the web experience. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam create-role \
  --region us-east-1 \
  --role-name "QBusinessWebRole-abcd1234" \
  --assume-role-policy-document file://qbusiness-web-trust-policy.json \
  --query 'Role.Arn' \
  --output text
```

Create an IAM policy for the web experience. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam create-policy \
  --region us-east-1 \
  --policy-name "QBusinessWebPolicy-abcd1234" \
  --policy-document file://qbusiness-web-permissions-policy.json \
  --query 'Policy.Arn' \
  --output text
```

Attach the policy to the role. Replace "123456789012" with the AWS account number. Replace "us-east-1" with the AWS Region name that you plan to use.

```bash
aws iam attach-role-policy \
  --region us-east-1 \
  --role-name "QBusinessWebRole-abcd1234" \
  --policy-arn "arn:aws:iam::123456789012:policy/QBusinessWebPolicy-abcd1234"
```

After creating the role and policy, wait for them to propagate (approximately 15 seconds).

Now, create the web experience. Replace "123456789012" with the AWS account number. Replace "app-abcd1234xmpl" with the name of your application ID that's returned from Step 4. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness create-web-experience \
  --region us-east-1 \
  --application-id "app-abcd1234xmpl" \
  --role-arn "arn:aws:iam::123456789012:role/QBusinessWebRole-abcd1234" \
  --query 'webExperienceId' \
  --output text
```

This command creates a web experience for your Amazon Q Business application and returns the web experience ID. Save the web experience id for the following command to use.

To get the URL for the web experience. Replace "app-abcd1234xmpl" with the name of your application ID that's returned from Step 4. Replace "wex-abcd1234xmpl" with your actual web experience id. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness get-web-experience \
  --region us-east-1 \
  --application-id "app-abcd1234xmpl" \
  --web-experience-id "wex-abcd1234xmpl" \
  --query 'defaultEndpoint' \
  --output text
```

This URL is where your users can access the Amazon Q Business application through a web browser.

To sign in and access the URL through a web browser, for username, use the user-name "qbusiness-user-abcd1234" that you specify in Step 3. For Password, choose "Forgot password" to receive the reset password email from your email that's specified in Step 3.

## Step 9: Verify your resources

To verify that your Amazon Q Business application has been created successfully, you can use the following commands. Replace "app-abcd1234xmpl" with your actual application ID that's returned in Step 4.

Check the application details. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness get-application --region us-east-1 --application-id "app-abcd1234xmpl"
```

List the user subscriptions. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness list-subscriptions --region us-east-1 --application-id "app-abcd1234xmpl"
```

If you created a web experience, list the web experiences. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness list-web-experiences --region us-east-1 --application-id "app-abcd1234xmpl"
```

## Cleanup

To avoid ongoing charges for the resources created in this tutorial, you should delete them when you're done.

If you created a web experience, delete it first. Replace "app-abcd1234xmpl" with your actual application ID that's returned in Step 4 and replace "wex-abcd1234xmpl" with your actual web experience ID that's returned in Step 8. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness delete-web-experience \
  --region us-east-1 \
  --application-id "app-abcd1234xmpl" \
  --web-experience-id "wex-abcd1234xmpl"
```

Delete the user assignment. Replace "arn:aws:sso::123456789012:application/ssoins-abcd1234xmpl/apl-abcd1234xmpl" with your application ARN that's returned from Step 4. Replace "1234abcd-xmpl-5678-efgh-90ijklmnopqr" with the user ID that's returned in Step 3. Replace "us-east-1" with the AWS Region where your IAM Identity Center instance is located.

```bash
aws sso-admin delete-application-assignment \
  --region us-east-1 \
  --application-arn "arn:aws:sso::123456789012:application/ssoins-abcd1234xmpl/apl-abcd1234xmpl" \
  --principal-id "1234abcd-xmpl-5678-efgh-90ijklmnopqr" \
  --principal-type USER
```

Delete the Amazon Q Business application. Replace "app-abcd1234xmpl" with your actual application ID that's returned in Step 4. Replace "us-east-1" with the AWS Region where your Amazon Q Business application is located.

```bash
aws qbusiness delete-application --region us-east-1 --application-id "app-abcd1234xmpl"
```

If you created a web experience role and policy, clean them up. Replace "123456789012" with your AWS account number. Replace "us-east-1" with the AWS Region name of your web experience role and policy.

```bash
aws iam detach-role-policy \
  --region us-east-1 \
  --role-name "QBusinessWebRole-abcd1234" \
  --policy-arn "arn:aws:iam::123456789012:policy/QBusinessWebPolicy-abcd1234"

aws iam delete-role --region us-east-1 --role-name "QBusinessWebRole-abcd1234"

aws iam delete-policy --region us-east-1 --policy-arn "arn:aws:iam::123456789012:policy/QBusinessWebPolicy-abcd1234"
```

Finally, clean up the main application role and policy that are created in Step 2. Replace "123456789012" with your AWS account number. Replace "us-east-1" with the AWS Region name of your web experience role and policy.


```bash
aws iam detach-role-policy \
  --region us-east-1 \
  --role-name "QBusinessServiceRole-abcd1234" \
  --policy-arn "arn:aws:iam::123456789012:policy/QBusinessPolicy-abcd1234"

aws iam delete-role --region us-east-1 --role-name "QBusinessServiceRole-abcd1234"

aws iam delete-policy --region us-east-1 --policy-arn "arn:aws:iam::123456789012:policy/QBusinessPolicy-abcd1234"
```

## Going to production

This tutorial is designed to help you learn how to use the Amazon Q Business API through the AWS CLI. For production deployments, consider the following best practices:

### Security best practices

1. **Follow the principle of least privilege**: Further restrict IAM policies to only the specific actions and resources needed.

2. **Implement identity federation**: Instead of creating users directly in IAM Identity Center, integrate with your existing identity provider using SAML or other federation mechanisms.

3. **Use customer-managed KMS keys**: For sensitive data, consider using customer-managed KMS keys instead of AWS managed keys for better control.

4. **Implement monitoring and alerting**: Set up CloudWatch metrics, logs, and alarms to monitor your Amazon Q Business application.

### Architecture best practices

1. **Consider high availability**: For production deployments, consider multi-region strategies for high availability.

2. **Implement automation**: Use infrastructure as code tools like AWS CloudFormation or AWS CDK instead of manual CLI commands.

3. **Develop a scaling strategy**: Plan for scaling your Amazon Q Business deployment as your user base grows.

4. **Implement cost controls**: Set up AWS Budgets and cost alarms to monitor and control costs.

For more information on AWS security best practices, see the [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) whitepaper.

For more information on AWS architecture best practices, see the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html).

## Next steps

Now that you've created an Amazon Q Business application, you might want to explore these related topics:

- [Adding data sources to your Amazon Q Business application](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/data-source-overview.html)
- [Managing user subscriptions in Amazon Q Business](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/tiers.html)
- [Customizing your Amazon Q Business web experience](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/customizing-web-experience.html)
- [Monitoring Amazon Q Business with CloudWatch](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/monitoring-overview.html)