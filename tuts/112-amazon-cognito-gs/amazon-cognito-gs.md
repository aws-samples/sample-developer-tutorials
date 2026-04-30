# Create a user pool and manage users with Amazon Cognito

## Overview

In this tutorial, you use the AWS CLI to create an Amazon Cognito user pool with email-based sign-in, add an app client, create a user, set a permanent password, and inspect the pool. You then delete the user pool during cleanup.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `cognito-idp:CreateUserPool`, `cognito-idp:CreateUserPoolClient`, `cognito-idp:AdminCreateUser`, `cognito-idp:AdminSetUserPassword`, `cognito-idp:ListUsers`, `cognito-idp:DescribeUserPool`, and `cognito-idp:DeleteUserPool`.

## Step 1: Create a user pool

Create a user pool that accepts email addresses as usernames and auto-verifies email.

```bash
RANDOM_ID=$(openssl rand -hex 4)
POOL_NAME="tut-pool-${RANDOM_ID}"

POOL_ID=$(aws cognito-idp create-user-pool --pool-name "$POOL_NAME" \
    --auto-verified-attributes email \
    --username-attributes email \
    --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
    --query 'UserPool.Id' --output text)
echo "Pool ID: $POOL_ID"
```

The `--username-attributes email` setting lets users sign in with their email address instead of a separate username. `--auto-verified-attributes email` marks email as verified when an admin creates the user with a verified email attribute.

## Step 2: Create an app client

Create an app client that allows username/password authentication.

```bash
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$POOL_ID" \
    --client-name "tutorial-app" \
    --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --query 'UserPoolClient.ClientId' --output text)
echo "Client ID: $CLIENT_ID"
```

App clients define how applications authenticate against the user pool. `ALLOW_USER_PASSWORD_AUTH` enables direct username/password sign-in, which is useful for server-side applications.

## Step 3: Create a user

Use the admin API to create a user directly, suppressing the welcome email.

```bash
aws cognito-idp admin-create-user --user-pool-id "$POOL_ID" \
    --username "tutorial@example.com" \
    --user-attributes Name=email,Value=tutorial@example.com Name=email_verified,Value=true \
    --temporary-password "TutPass1!" \
    --message-action SUPPRESS \
    --query 'User.{Username:Username,Status:UserStatus,Created:UserCreateDate}' --output table
```

`--message-action SUPPRESS` prevents Cognito from sending an invitation email. The user is created in `FORCE_CHANGE_PASSWORD` status, meaning they must change their password on first sign-in.

## Step 4: Set a permanent password

Set a permanent password so the user moves to `CONFIRMED` status without going through the change-password flow.

```bash
aws cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" \
    --username "tutorial@example.com" \
    --password "Tutorial1Pass!" --permanent
```

In production, you would let users change their own password through the authentication flow. The admin API is useful for migrations and testing.

## Step 5: List users

List all users in the pool to confirm the user status.

```bash
aws cognito-idp list-users --user-pool-id "$POOL_ID" \
    --query 'Users[].{Username:Username,Status:UserStatus,Enabled:Enabled}' --output table
```

## Step 6: Describe the user pool

View the pool configuration and user count.

```bash
aws cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
    --query 'UserPool.{Name:Name,Id:Id,Status:Status,Users:EstimatedNumberOfUsers,MFA:MfaConfiguration}' \
    --output table
```

## Cleanup

Delete the user pool. This removes the pool, all users, and all app clients.

```bash
aws cognito-idp delete-user-pool --user-pool-id "$POOL_ID"
```

The Cognito free tier covers 50,000 MAUs. Since this tutorial only creates a user without authenticating through a token endpoint, there are no charges.

The script automates all steps including cleanup:

```bash
bash amazon-cognito-gs.sh
```

## Related resources

- [Getting started with user pools](https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-user-pools.html)
- [Creating a user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-as-user-directory.html)
- [Managing users](https://docs.aws.amazon.com/cognito/latest/developerguide/how-to-manage-user-accounts.html)
- [Amazon Cognito pricing](https://aws.amazon.com/cognito/pricing/)
