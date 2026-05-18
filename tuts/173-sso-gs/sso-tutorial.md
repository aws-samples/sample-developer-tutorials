# Tutorial for Getting Started with AWS SSO

## Prerequisites
- An AWS account
- Python installed
- Boto3 library installed
- AWS SSO configured

## Steps

1. **Set up your environment**:
    Ensure you have Python and Boto3 installed. You can install Boto3 using pip:
    ```sh
    pip install boto3
    ```

2. **Configure AWS CLI with SSO**:
    Follow the [official AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html) to configure the AWS CLI with SSO.

3. **Python Script to Interact with AWS SSO**:
    Create a Python script to list accounts, roles, and retrieve role credentials.

    ```python
    import boto3
    import time
    import random

    suffix = str(int(time.time()))[-6:] + str(random.randint(1, 100))
    client = boto3.client('sso', region_name='us-east-1')

    try:
        accounts = client.list_accounts()
        print("List Accounts:", accounts)
        
        account_id = accounts['accountList'][0]['accountId']
        roles = client.list_account_roles(accountId=account_id)
        print("List Account Roles:", roles)
        
        role_credentials = client.get_role_credentials(
            accountId=account_id,
            roleName=roles['roleList'][0]['roleName'],
            accessToken="dummy-token"  # Replace with actual token in real use
        )
        print("Get Role Credentials:", role_credentials)
        
        print("PASS")
    except Exception as e:
        print("Error:", e)
    ```

4. **Run the Script**:
    Execute the script to see the output of listed accounts, roles, and role credentials.

## Clean up
- No resources are created in this tutorial that require manual cleanup.

## Next steps
- Explore more features of AWS SSO, such as [assigning access](https://docs.aws.amazon.com/singlesignon/latest/userguide/userassignments.html) and [managing permissions](https://docs.aws.amazon.com/singlesignon/latest/userguide/permissions.html).