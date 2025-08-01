# Getting started with Amazon Cognito user pools using the AWS CLI

This tutorial guides you through creating and configuring an Amazon Cognito user pool using the AWS Command Line Interface (AWS CLI). You'll learn how to set up authentication for your applications, create users, and test the authentication flow.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic understanding of authentication concepts.
4. [Sufficient permissions](https://docs.aws.amazon.com/cognito/latest/developerguide/security-iam-awsmanpol.html) to create and manage Amazon Cognito resources in your AWS account. The `AmazonCognitoPowerUser` managed policy is sufficient for this tutorial.

**Time to complete**: Approximately 20-30 minutes

**Cost**: This tutorial uses resources that are included in the AWS Free Tier. If you're a new AWS customer, you can use Amazon Cognito at no cost within certain limits. The resources created in this tutorial fall within the free tier limits:
- 50,000 monthly active users (MAUs) for the standard tier
- No cost for user pool creation, app clients, or domains

## Create a user pool

A user pool is a user directory in Amazon Cognito. It allows your users to sign in to your web or mobile app through Amazon Cognito. Let's start by creating a user pool with basic settings.

The following command creates a user pool named "MyUserPool" with email as a verified attribute and username attribute, a standard password policy, and MFA disabled:

```bash
aws cognito-idp create-user-pool \
  --pool-name "MyUserPool" \
  --auto-verified-attributes email \
  --username-attributes email \
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
  --schema '[{"Name":"email","Required":true,"Mutable":true}]' \
  --mfa-configuration OFF
```

After running this command, you'll receive a JSON response containing details about your new user pool. Make note of the `Id` value (which looks like `us-east-1_abcd1234`), as you'll need it for subsequent commands.

## Create an app client

App clients are applications that can call unauthenticated API operations in your user pool. You need to create an app client to allow your application to work with the user pool.

Use the following command to create an app client, replacing `YOUR_USER_POOL_ID` with the ID you received in the previous step:

```bash
aws cognito-idp create-user-pool-client \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --client-name "MyAppClient" \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --callback-urls '["https://localhost:3000/callback"]'
```

This command creates an app client with no client secret (suitable for public clients like single-page applications), support for username/password authentication, and a callback URL for redirecting after authentication. Save the `ClientId` from the output for future use.

## Set up a domain for your user pool

To use the hosted UI and authentication endpoints, you need to set up a domain for your user pool:

```bash
aws cognito-idp create-user-pool-domain \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --domain "my-auth-domain"
```

Replace `YOUR_USER_POOL_ID` with your user pool ID and choose a unique domain prefix. The domain will be available at `https://my-auth-domain.auth.REGION.amazoncognito.com`.

## View user pool details

You can view the details of your user pool at any time using the following command:

```bash
aws cognito-idp describe-user-pool \
  --user-pool-id "YOUR_USER_POOL_ID"
```

This command returns comprehensive information about your user pool, including its policies, schema, and configuration.

## View app client details

Similarly, you can view the details of your app client:

```bash
aws cognito-idp describe-user-pool-client \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --client-id "YOUR_CLIENT_ID"
```

Replace `YOUR_USER_POOL_ID` and `YOUR_CLIENT_ID` with your actual values.

## Create a user as an administrator

You can create users directly in your user pool as an administrator:

```bash
aws cognito-idp admin-create-user \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --username "user@example.com" \
  --user-attributes Name=email,Value=user@example.com Name=email_verified,Value=true \
  --temporary-password "TEMPORARY_PASSWORD"
```

This creates a user with email as username, verified email status, and a temporary password that must be changed on first login. Replace `TEMPORARY_PASSWORD` with a strong password of your choice.

## Enable self-registration

Alternatively, you can allow users to sign themselves up. First, a user initiates the sign-up process:

```bash
aws cognito-idp sign-up \
  --client-id "YOUR_CLIENT_ID" \
  --username "user2@example.com" \
  --password "STRONG_PASSWORD" \
  --user-attributes Name=email,Value=user2@example.com
```

Replace `YOUR_CLIENT_ID` with your app client ID and `STRONG_PASSWORD` with a secure password. In a real scenario, the user would receive a confirmation code via email.

## Confirm user registration

After a user signs up, they need to confirm their registration with the confirmation code sent to their email:

```bash
aws cognito-idp confirm-sign-up \
  --client-id "YOUR_CLIENT_ID" \
  --username "user2@example.com" \
  --confirmation-code "123456"
```

Replace `123456` with the actual confirmation code received by the user. For testing purposes, you can also confirm a user as an administrator:

```bash
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --username "user2@example.com"
```

## Authenticate a user

Once a user is confirmed, they can authenticate:

```bash
aws cognito-idp initiate-auth \
  --client-id "YOUR_CLIENT_ID" \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=user2@example.com,PASSWORD="STRONG_PASSWORD"
```

This returns authentication tokens that your application can use to authorize API calls.

## List users in the user pool

To view all users in your user pool:

```bash
aws cognito-idp list-users \
  --user-pool-id "YOUR_USER_POOL_ID"
```

This command returns information about all users in your user pool, including their attributes and status.

## Going to production

This tutorial demonstrates basic Amazon Cognito user pool functionality for learning purposes. When implementing authentication in a production environment, consider the following additional measures:

1. **Enable Multi-Factor Authentication (MFA)**: For production applications, enable MFA to add an extra layer of security. See [Adding MFA to a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html).

2. **Implement monitoring and logging**: Set up CloudWatch metrics and logs to monitor authentication events and detect suspicious activities.

3. **Consider high availability**: For production applications, consider multi-region strategies for high availability.

4. **Implement proper token handling**: Securely store and validate tokens in your application.

5. **Use stronger password policies**: Consider requiring symbols and longer passwords for production environments.

6. **Enable advanced security features**: Amazon Cognito offers advanced security features like adaptive authentication and compromised credential checking.

For more information on building secure and scalable authentication systems, refer to:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Amazon Cognito Security Best Practices](https://docs.aws.amazon.com/cognito/latest/developerguide/security.html)

## Clean up resources

When you no longer need the resources created in this tutorial, you should delete them to avoid incurring charges:

```bash
# First delete the domain
aws cognito-idp delete-user-pool-domain \
  --user-pool-id "YOUR_USER_POOL_ID" \
  --domain "my-auth-domain"

# Then delete the user pool
aws cognito-idp delete-user-pool \
  --user-pool-id "YOUR_USER_POOL_ID"
```

Deleting the user pool will also delete all associated resources, including app clients and users.

## Next steps

Now that you've learned the basics of working with Amazon Cognito user pools using the AWS CLI, you can explore more advanced features:

- [Add multi-factor authentication (MFA) to a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-mfa.html)
- [Customize the built-in sign-in and sign-up webpages](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-app-ui-customization.html)
- [Add social identity providers to a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-social-idp.html)
- [Add SAML identity providers to a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-saml-idp.html)
- [Use Amazon Cognito user pools with AWS Lambda triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html)
