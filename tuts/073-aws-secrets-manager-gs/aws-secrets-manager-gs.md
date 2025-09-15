# Moving hardcoded secrets to AWS Secrets Manager

This tutorial guides you through the process of moving hardcoded secrets from your code to AWS Secrets Manager. By storing your secrets in Secrets Manager, you improve security by eliminating plaintext secrets in your code and gain the ability to rotate secrets without changing your code.

## Prerequisites

Before you begin this tutorial, you need:

- An AWS account with permissions to create IAM roles and use AWS Secrets Manager
- The AWS Command Line Interface (AWS CLI) installed and configured
- Basic knowledge of the AWS CLI and IAM
- Approximately 15 minutes to complete the tutorial

### Costs

This tutorial creates IAM roles and a secret in AWS Secrets Manager. The IAM roles are free, and AWS Secrets Manager costs approximately $0.40 per secret per month. If you complete this tutorial in one hour and then delete the resources, the cost will be less than $0.01. To avoid ongoing charges, follow the cleanup steps at the end of this tutorial.

## Create IAM roles

In this tutorial, you'll use two IAM roles to manage permissions to your secret:

- A role for managing secrets (SecretsManagerAdmin)
- A role for retrieving secrets at runtime (RoleToRetrieveSecretAtRuntime)

First, create the SecretsManagerAdmin role. This role will have permissions to create and manage secrets.

```bash
aws iam create-role \
    --role-name SecretsManagerAdmin \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
```

The command returns information about the newly created role:

```json
{
    "Role": {
        "Path": "/",
        "RoleName": "SecretsManagerAdmin",
        "RoleId": "AROAEXAMPLEXAMPLE",
        "Arn": "arn:aws:iam::123456789012:role/SecretsManagerAdmin",
        "CreateDate": "2025-01-13T00:20:27Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ec2.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

Next, attach the SecretsManagerReadWrite policy to the admin role. This policy grants permissions to create and manage secrets in AWS Secrets Manager.

```bash
aws iam attach-role-policy \
    --role-name SecretsManagerAdmin \
    --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
```

Now, create the RoleToRetrieveSecretAtRuntime role. This role will be used by your application to retrieve secrets at runtime.

```bash
aws iam create-role \
    --role-name RoleToRetrieveSecretAtRuntime \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
```

The command returns information about the newly created role:

```json
{
    "Role": {
        "Path": "/",
        "RoleName": "RoleToRetrieveSecretAtRuntime",
        "RoleId": "AROAEXAMPLEXAMPLE",
        "Arn": "arn:aws:iam::123456789012:role/RoleToRetrieveSecretAtRuntime",
        "CreateDate": "2025-01-13T00:20:29Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ec2.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

Wait a few moments for the IAM roles to be fully created and propagated throughout the AWS system.

## Create a secret in AWS Secrets Manager

Now that you have the necessary IAM roles, you can create a secret in AWS Secrets Manager. In this example, you'll create a secret for an API key with a client ID and client secret.

```bash
aws secretsmanager create-secret \
    --name "MyAPIKey" \
    --description "API key for my application" \
    --secret-string '{"ClientID":"my_client_id","ClientSecret":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}'
```

The command returns information about the newly created secret:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:MyAPIKey-abcd1234",
    "Name": "MyAPIKey",
    "VersionId": "abcd1234-xmpl-4321-abcd-1234567890ab"
}
```

Next, you need to get your AWS account ID to use in the resource policy:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
```

Now, add a resource policy to the secret to allow the RoleToRetrieveSecretAtRuntime role to access it. Store the ARN of your secret in a variable to use in the resource policy:

```bash
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id "MyAPIKey" --query "ARN" --output text)

aws secretsmanager put-resource-policy \
    --secret-id "MyAPIKey" \
    --resource-policy '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::'$ACCOUNT_ID':role/RoleToRetrieveSecretAtRuntime"
                },
                "Action": "secretsmanager:GetSecretValue",
                "Resource": "'$SECRET_ARN'"
            }
        ]
    }' \
    --block-public-policy
```

The command returns information about the secret:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:MyAPIKey-abcd1234",
    "Name": "MyAPIKey"
}
```

## Update your application code

Now that you've stored your secret in AWS Secrets Manager, you need to update your application code to retrieve the secret instead of using hardcoded values. Here's an example using Python:

```python
# Before: Hardcoded secrets (insecure)
# client_id = "my_client_id"
# client_secret = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# After: Retrieve secrets from AWS Secrets Manager
import boto3
import json
import base64
from botocore.exceptions import ClientError

def get_secret():
    secret_name = "MyAPIKey"
    region_name = "us-east-1"  # Replace with your region

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # Handle exceptions like ResourceNotFoundException, InvalidParameterException, etc.
        print(f"Error retrieving secret: {e}")
        raise e
    else:
        # Decrypts secret using the associated KMS key
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret)
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return json.loads(decoded_binary_secret)

# Use the secret in your application
try:
    secret_dict = get_secret()
    client_id = secret_dict['ClientID']
    client_secret = secret_dict['ClientSecret']

    # Now use client_id and client_secret in your application
    print(f"Successfully retrieved secret for client ID: {client_id}")
except Exception as e:
    # Implement appropriate error handling for your application
    print(f"Failed to retrieve secret: {e}")
```

To test that your application can retrieve the secret, you can use the AWS CLI:

```bash
aws secretsmanager get-secret-value \
    --secret-id "MyAPIKey" \
    --query "{ARN:ARN,Name:Name,VersionId:VersionId,VersionStages:VersionStages,CreatedDate:CreatedDate}"
```

The command returns metadata about the secret (without showing the actual secret value):

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:MyAPIKey-abcd1234",
    "Name": "MyAPIKey",
    "VersionId": "abcd1234-xmpl-4321-abcd-1234567890ab",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": 1673596840.114
}
```

## Update the secret

After updating your application to retrieve secrets from Secrets Manager, you can update the secret with new values when needed. This is particularly useful when rotating credentials.

```bash
aws secretsmanager update-secret \
    --secret-id "MyAPIKey" \
    --secret-string '{"ClientID":"my_new_client_id","ClientSecret":"bPxRfiCYEXAMPLEKEY/wJalrXUtnFEMI/K7MDENG"}'
```

The command returns information about the updated secret:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:MyAPIKey-abcd1234",
    "Name": "MyAPIKey",
    "VersionId": "abcd1234-xmpl-5678-abcd-1234567890cd"
}
```

Verify that the secret was updated by retrieving it again:

```bash
aws secretsmanager get-secret-value \
    --secret-id "MyAPIKey" \
    --query "{ARN:ARN,Name:Name,VersionId:VersionId,VersionStages:VersionStages,CreatedDate:CreatedDate}"
```

The command returns metadata about the updated secret:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:MyAPIKey-abcd1234",
    "Name": "MyAPIKey",
    "VersionId": "abcd1234-xmpl-5678-abcd-1234567890cd",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": 1673596843.522
}
```

Notice that the VersionId has changed, indicating that this is a new version of the secret.

## Going to production

This tutorial demonstrates the basic functionality of AWS Secrets Manager, but there are additional considerations for production environments:

### Security best practices

1. **Use specific resource ARNs**: The resource policy should specify the exact ARN of the secret rather than using wildcards.

2. **Implement secret rotation**: Set up automatic rotation for your secrets using Lambda functions to enhance security.

3. **Use appropriate trust policies**: Customize IAM role trust policies based on the service that needs to access the secret (Lambda, ECS, etc.) rather than using EC2 as a generic service principal.

4. **Add condition keys**: Use condition keys in your policies to further restrict access based on factors like source IP or requiring MFA.

5. **Avoid plaintext secrets in commands**: When creating or updating secrets, consider using files or environment variables instead of typing secrets directly in the command line.

### Architecture considerations

1. **Implement caching**: To improve performance and reduce costs, implement client-side caching of secrets with appropriate TTL values.

2. **Consider multi-region deployments**: For applications that operate in multiple regions, replicate secrets across regions to improve availability and reduce latency.

3. **Set up monitoring**: Configure CloudTrail and CloudWatch to monitor and alert on suspicious access to your secrets.

4. **Use infrastructure as code**: For production environments, manage your secrets using AWS CloudFormation or AWS CDK rather than manual CLI commands.

For more information on AWS security best practices, see the [AWS Well-Architected Framework Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html).

## Clean up resources

To avoid ongoing charges, delete the resources you created in this tutorial:

```bash
# Delete the secret
aws secretsmanager delete-secret \
    --secret-id "MyAPIKey" \
    --force-delete-without-recovery

# Delete the IAM roles
aws iam delete-role --role-name "RoleToRetrieveSecretAtRuntime"

aws iam detach-role-policy \
    --role-name "SecretsManagerAdmin" \
    --policy-arn "arn:aws:iam::aws:policy/SecretsManagerReadWrite"

aws iam delete-role --role-name "SecretsManagerAdmin"
```

## Next steps

Now that you've learned how to move hardcoded secrets to AWS Secrets Manager, consider these next steps:

- Implement [automatic rotation for your secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html) to enhance security
- Learn how to [cache secrets in your application](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets.html) to improve performance and reduce costs
- For multi-region applications, explore [replicating secrets across regions](https://docs.aws.amazon.com/secretsmanager/latest/userguide/replicate-secrets.html) to improve latency
- Use [Amazon CodeGuru Reviewer](https://docs.aws.amazon.com/codeguru/latest/reviewer-ug/welcome.html) to find hardcoded secrets in your Java and Python applications
- Learn about different ways to [grant permissions to secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_resource-policies.html) using resource-based policies
