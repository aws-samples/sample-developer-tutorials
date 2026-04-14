# Store and retrieve secrets with AWS Secrets Manager

## Overview

In this tutorial, you use the AWS CLI to create a secret containing JSON database credentials, retrieve and update the secret value, inspect secret metadata, and tag the secret for organization. You then delete the secret immediately without a recovery window.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `secretsmanager:CreateSecret`, `secretsmanager:GetSecretValue`, `secretsmanager:PutSecretValue`, `secretsmanager:DescribeSecret`, `secretsmanager:TagResource`, and `secretsmanager:DeleteSecret`.

## Step 1: Create a secret

Create a secret with JSON-formatted database credentials.

```bash
SECRET_NAME="tutorial/db-creds-$(openssl rand -hex 4)"

SECRET_ARN=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Tutorial database credentials" \
    --secret-string '{"username":"admin","password":"tutorial-pass-12345","engine":"mysql","host":"db.example.com","port":3306}' \
    --query 'ARN' --output text)
echo "Secret ARN: $SECRET_ARN"
```

Secrets Manager stores the secret string as-is. JSON format is conventional for database credentials because the SDKs and rotation functions expect it.

## Step 2: Retrieve the secret

```bash
aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
    --query '{Name:Name,Value:SecretString}' --output table
```

The `SecretString` field contains the JSON you stored. For binary secrets, use `SecretBinary` instead.

## Step 3: Update the secret value

Replace the secret value with new credentials using `put-secret-value`.

```bash
aws secretsmanager put-secret-value --secret-id "$SECRET_NAME" \
    --secret-string '{"username":"admin","password":"new-secure-pass-67890","engine":"mysql","host":"db.example.com","port":3306}'
```

Secrets Manager creates a new version of the secret. The previous version is still accessible by version ID.

## Step 4: Retrieve the updated secret

Confirm the secret now contains the updated password.

```bash
aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
    --query 'SecretString' --output text | python3 -m json.tool
```

## Step 5: Describe the secret

View the secret's metadata, including creation date, last changed date, and version count.

```bash
aws secretsmanager describe-secret --secret-id "$SECRET_NAME" \
    --query '{Name:Name,Description:Description,Created:CreatedDate,LastChanged:LastChangedDate,Versions:VersionIdsToStages|length(@)}' \
    --output table
```

`describe-secret` returns metadata only — it never returns the secret value.

## Step 6: Tag the secret

Add tags to organize and control access to the secret.

```bash
aws secretsmanager tag-resource --secret-id "$SECRET_NAME" \
    --tags Key=Environment,Value=tutorial Key=Application,Value=database

aws secretsmanager describe-secret --secret-id "$SECRET_NAME" \
    --query 'Tags[].{Key:Key,Value:Value}' --output table
```

## Cleanup

Delete the secret immediately with `--force-delete-without-recovery`. This skips the default 7–30 day recovery window.

```bash
aws secretsmanager delete-secret --secret-id "$SECRET_NAME" \
    --force-delete-without-recovery
```

Without `--force-delete-without-recovery`, Secrets Manager schedules deletion after a recovery window (default 30 days), during which you can restore the secret.

The script automates all steps including cleanup:

```bash
bash aws-secrets-manager-gs.sh
```

## Related resources

- [Getting started with Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html)
- [Create and manage secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/managing-secrets.html)
- [Rotate secrets automatically](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [Tag secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/managing-secrets_tagging.html)
