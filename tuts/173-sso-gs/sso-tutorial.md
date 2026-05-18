# Tutorial: Using AWS SSO with Boto3

## Prerequisites

- Python installed on your machine
- Boto3 library installed (`$ pip install boto3`)
- AWS SSO setup with necessary permissions
- SSO start URL, client ID, and client secret

## Steps

### 1. Initialize a session using Amazon SSO credentials

```python
import boto3
import uuid
import time

sso = boto3.client('sso')
sso_oidc = boto3.client('sso-oidc')
```

### 2. Get the SSO token

```python
def get_sso_token(region, start_url, client_id, client_secret):
    device_code_response = sso_oidc.start_device_authorization(
        clientId=client_id,
        clientSecret=client_secret,
        startUrl=start_url
    )
    device_code = device_code_response['deviceCode']
    user_code = device_code_response['userCode']
    verification_uri = device_code_response['verificationUriComplete']
    
    print(f"Navigate to {verification_uri} and enter code {user_code}")
    
    interval = int(device_code_response['interval'])
    max_attempts = int(device_code_response['expiresIn']) // interval

    for _ in range(max_attempts):
        try:
            access_token_response = sso_oidc.create_token(
                grantType='urn:ietf:params:oauth:grant-type:device_code',
                deviceCode=device_code,
                clientId=client_id,
                clientSecret=client_secret
            )
            return access_token_response['accessToken']
        except sso_oidc.exceptions.AuthorizationPendingException:
            time.sleep(interval)
    
    raise Exception("Failed to obtain access token")
```

### 3. Get role credentials

```python
def get_role_credentials(access_token, account_id, role_name, region):
    sso = boto3.client('sso', region_name=region)
    role_credentials = sso.get_role_credentials(
        roleName=role_name,
        accountId=account_id,
        accessToken=access_token
    )
    print("GetRoleCredentials status: SUCCESS")
    return role_credentials
```

### 4. List account roles

```python
def list_account_roles(access_token, account_id, region):
    sso = boto3.client('sso', region_name=region)
    account_roles = sso.list_account_roles(
        accountId=account_id,
        accessToken=access_token
    )
    print("ListAccountRoles status: SUCCESS")
    return account_roles
```

### 5. List accounts

```python
def list_accounts(access_token, region):
    sso = boto3.client('sso', region_name=region)
    accounts = sso.list_accounts(
        accessToken=access_token
    )
    print("ListAccounts status: SUCCESS")
    return accounts
```

### 6. Logout

```python
def logout(access_token, region):
    sso = boto3.client('sso', region_name=region)
    sso.logout(
        accessToken=access_token
    )
    print("Logout status: SUCCESS")
```

### 7. Main execution

```python
if __name__ == "__main__":
    start_url = 'https://your-sso-start-url'
    region = 'your-region'
    client_id = 'your-client-id'
    client_secret = 'your-client-secret'
    account_id = '123456789012'
    role_name = 'your-role-name'

    access_token = get_sso_token(region, start_url, client_id, client_secret)
    role_credentials = get_role_credentials(access_token, account_id, role_name, region)
    account_roles = list_account_roles(access_token, account_id, region)
    accounts = list_accounts(access_token, region)
    logout(access_token, region)
```

## Clean up

Ensure you log out after completing your tasks to secure your session.

## Next steps

- Explore other AWS services using the obtained role credentials.
- Automate more tasks using Boto3 and AWS SSO.