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
        accessToken="dummy-token"
    )
    print("Get Role Credentials:", role_credentials)
    
    print("PASS")
except Exception as e:
    print("Error:", e)