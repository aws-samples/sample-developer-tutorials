import boto3
import uuid
import time

# Initialize a session using Amazon SSO credentials
sso = boto3.client('sso')
sso_oidc = boto3.client('sso-oidc')

# Get the SSO token
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

# Get role credentials
def get_role_credentials(access_token, account_id, role_name, region):
    sso = boto3.client('sso', region_name=region)
    role_credentials = sso.get_role_credentials(
        roleName=role_name,
        accountId=account_id,
        accessToken=access_token
    )
    print("GetRoleCredentials status: SUCCESS")
    return role_credentials

# List account roles
def list_account_roles(access_token, account_id, region):
    sso = boto3.client('sso', region_name=region)
    account_roles = sso.list_account_roles(
        accountId=account_id,
        accessToken=access_token
    )
    print("ListAccountRoles status: SUCCESS")
    return account_roles

# List accounts
def list_accounts(access_token, region):
    sso = boto3.client('sso', region_name=region)
    accounts = sso.list_accounts(
        accessToken=access_token
    )
    print("ListAccounts status: SUCCESS")
    return accounts

# Logout
def logout(access_token, region):
    sso = boto3.client('sso', region_name=region)
    sso.logout(
        accessToken=access_token
    )
    print("Logout status: SUCCESS")

# Main execution
if __name__ == "__main__":
    start_url = 'https://your-sso-start-url'
    client_id = 'your-client-id'
    client_secret = 'your-client-secret'
    region = 'us-west-2'
    
    try:
        access_token = get_sso_token(region, start_url, client_id, client_secret)
        
        account_id = 'your-account-id'
        role_name = 'your-role-name'
        
        get_role_credentials(access_token, account_id, role_name, region)
        list_account_roles(access_token, account_id, region)
        list_accounts(access_token, region)
        logout(access_token, region)
        
        print("PASS")
    except Exception as e:
        print(f"An error occurred: {e}")