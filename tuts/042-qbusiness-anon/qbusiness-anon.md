# Creating an Amazon Q Business application environment for anonymous access

This tutorial guides you through creating an Amazon Q Business application environment that supports anonymous access using the AWS Command Line Interface (AWS CLI). Anonymous access enables unauthenticated users to interact with the Amazon Q generative AI assistant and access selected enterprise data without requiring credentials.

## Topics

- [Prerequisites](#prerequisites)
- [Create an IAM role for Amazon Q Business](#create-an-iam-role-for-amazon-q-business)
- [Create an Amazon Q Business application with anonymous access](#create-an-amazon-q-business-application-with-anonymous-access)
- [Verify the application creation](#verify-the-application-creation)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/setting-up.html) to create and manage Amazon Q Business resources in your AWS account.

### Cost considerations

The resources created in this tutorial have the following cost implications:

- **Amazon Q Business Anonymous Application**: Billing for anonymous access application environments is based on usage. You are charged for chat API requests and data processing. There is no cost for just creating the application without usage.
- **IAM Role and Policy**: There is no cost for creating IAM resources.

For the most current and detailed pricing information, refer to the [Amazon Q Business pricing page](https://aws.amazon.com/q/business/pricing/).

Let's get started with creating an Amazon Q Business application environment for anonymous access.

## Create an IAM role for Amazon Q Business

First, you need to create an IAM role that grants Amazon Q Business permissions to access the AWS resources it needs to create your application environment.

**Create a trust policy document**

Create a JSON file that defines the trust relationship for the IAM role. This policy allows the Amazon Q Business service to assume the role.

```bash
cat > qbusiness-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "qbusiness.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This command creates a file named `qbusiness-trust-policy.json` with the necessary trust policy for Amazon Q Business.

**Create the IAM role**

Now, create the IAM role using the trust policy document you just created.

```bash
aws iam create-role --role-name QBusinessServiceRole \
  --assume-role-policy-document file://qbusiness-trust-policy.json
```

The command creates an IAM role named `QBusinessServiceRole` that can be assumed by the Amazon Q Business service.

**Attach permissions to the role**

Attach the necessary permissions to the IAM role to allow Amazon Q Business to access the required AWS resources.

```bash
aws iam attach-role-policy --role-name QBusinessServiceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonQFullAccess
```

This command attaches the `AmazonQFullAccess` managed policy to the role, which provides the permissions needed by Amazon Q Business.

**Get the role ARN**

Retrieve the Amazon Resource Name (ARN) of the IAM role, which you'll need when creating the Amazon Q Business application.

```bash
aws iam get-role --role-name QBusinessServiceRole --query "Role.Arn" --output text
```

The command returns the ARN of the IAM role, which should look like `arn:aws:iam::123456789012:role/QBusinessServiceRole`.

## Create an Amazon Q Business application with anonymous access

Now that you have created the IAM role, you can create an Amazon Q Business application environment with anonymous access.

**Create the application**

Use the following command to create an Amazon Q Business application with anonymous access.

```bash
aws qbusiness create-application \
  --display-name "AnonymousQBusinessApp" \
  --identity-type ANONYMOUS \
  --role-arn arn:aws:iam::123456789012:role/QBusinessServiceRole \
  --description "Amazon Q Business application with anonymous access"
```

Replace `arn:aws:iam::123456789012:role/QBusinessServiceRole` with the actual ARN of the IAM role you created earlier. This command creates an Amazon Q Business application with anonymous access using the specified IAM role.

The response will include details about the application, including its ID, which you'll need for subsequent operations.

```json
{
    "applicationId": "abcd1234-5678-90ab-cdef-11223344xmpl",
    "applicationArn": "arn:aws:qbusiness:us-east-1:123456789012:application/abcd1234-5678-90ab-cdef-11223344xmpl",
    "displayName": "AnonymousQBusinessApp",
    "identityType": "ANONYMOUS",
    "roleArn": "arn:aws:iam::123456789012:role/QBusinessServiceRole",
    "status": "CREATING",
    "description": "Amazon Q Business application with anonymous access",
    "createdAt": 1673596800.000,
    "updatedAt": 1673596800.000,
    "error": {},
    "attachmentsConfiguration": {
        "attachmentsControlMode": "DISABLED"
    },
    "autoSubscriptionConfiguration": {}
}
```

Note the `applicationId` from the response, as you'll need it for subsequent operations.

## Verify the application creation

After creating the application, you should verify that it was created successfully and is in the `ACTIVE` state.

**Get application details**

Use the following command to retrieve details about your application.

```bash
aws qbusiness get-application --application-id abcd1234-5678-90ab-cdef-11223344xmpl
```

Replace `abcd1234-5678-90ab-cdef-11223344xmpl` with the actual application ID from the previous step. The command returns detailed information about your application.

```json
{
    "displayName": "AnonymousQBusinessApp",
    "applicationId": "abcd1234-5678-90ab-cdef-11223344xmpl",
    "applicationArn": "arn:aws:qbusiness:us-east-1:123456789012:application/abcd1234-5678-90ab-cdef-11223344xmpl",
    "identityType": "ANONYMOUS",
    "roleArn": "arn:aws:iam::123456789012:role/QBusinessServiceRole",
    "status": "ACTIVE",
    "description": "Amazon Q Business application with anonymous access",
    "createdAt": 1673596800.000,
    "updatedAt": 1673596800.000,
    "error": {},
    "attachmentsConfiguration": {
        "attachmentsControlMode": "DISABLED"
    },
    "autoSubscriptionConfiguration": {}
}
```

Verify that the `status` field shows `ACTIVE`, which indicates that the application is ready to use.

## Clean up resources

When you're finished with your Amazon Q Business application, you should delete it and the associated IAM role to avoid incurring additional charges.

**Delete the application**

Use the following command to delete your Amazon Q Business application.

```bash
aws qbusiness delete-application --application-id abcd1234-5678-90ab-cdef-11223344xmpl
```

Replace `abcd1234-5678-90ab-cdef-11223344xmpl` with the actual application ID. This command deletes the Amazon Q Business application.

**Detach the policy from the IAM role**

Before deleting the IAM role, you need to detach the policy from it.

```bash
aws iam detach-role-policy --role-name QBusinessServiceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonQFullAccess
```

This command detaches the `AmazonQFullAccess` policy from the IAM role.

**Delete the IAM role**

Finally, delete the IAM role you created.

```bash
aws iam delete-role --role-name QBusinessServiceRole
```

This command deletes the IAM role named `QBusinessServiceRole`.

## Going to production

This tutorial demonstrates how to create a basic Amazon Q Business application with anonymous access for educational purposes. When moving to a production environment, consider the following best practices:

### Security best practices

1. **Use least privilege permissions**: Instead of using the `AmazonQFullAccess` managed policy, create a custom IAM policy with only the permissions required for your specific use case.

2. **Implement content filtering**: Configure blocked words and other guardrails to prevent inappropriate content generation in your anonymous application.

3. **Secure data sources**: Only use publicly available data sources without access control lists (ACLs) with anonymous applications. Ensure any data sources are properly secured.

### Architecture best practices

1. **Implement monitoring and logging**: Set up CloudWatch logs and metrics to monitor your application's performance and usage.

2. **Consider high availability**: For production workloads, implement appropriate high availability and disaster recovery strategies.

3. **Implement cost monitoring**: Set up cost monitoring and alerts to track usage and prevent unexpected charges.

4. **Use infrastructure as code**: Consider using AWS CloudFormation or AWS CDK to manage your resources programmatically.

For more information on AWS security best practices, see the [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) guide. For architecture best practices, refer to the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html).

## Next steps

Now that you've learned how to create an Amazon Q Business application environment with anonymous access using the AWS CLI, explore other Amazon Q Business features:

1. **Making authenticated API calls** - [Make authenticated API calls for your anonymous application](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/making-sigv4-authenticated-api-calls-anonymous-applications.html).
2. **Managing resources** - [Manage resources for your anonymous application](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/managing-anonymous-app-resources.html).
3. **Embedding Amazon Q** - [Embed Amazon Q Business in your applications](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/embed-amazon-q-business.html).
4. **Using Chat APIs** - Integrate with your application using the Chat, ChatSync, and PutFeedback APIs.

For more information about available AWS CLI commands for Amazon Q Business, run `aws qbusiness help`.
