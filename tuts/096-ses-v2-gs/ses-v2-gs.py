import boto3
import time

region = 'us-east-1'
suffix = str(int(time.time()))[-6:]
iam_role_arn = 'arn:aws:iam::559823168634:role/doc-babu-sesv2-role'
sesv2 = boto3.client('sesv2', region_name=region)

def create_configuration_set():
    name = f'config-set-{suffix}'
    print(f"Creating Configuration Set: {name}")
    sesv2.create_configuration_set(ConfigurationSetName=name, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'ses-v2-gs'}])
    print(f"Created Configuration Set: {name}")

def create_contact_list():
    name = f'contact-list-{suffix}'
    print(f"Creating Contact List: {name}")
    sesv2.create_contact_list(ContactListName=name, Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'ses-v2-gs'}])
    print(f"Created Contact List: {name}")

def create_contact():
    contact_list_name = f'contact-list-{suffix}'
    email_address = f'test{suffix}@example.com'
    print(f"Creating Contact: {email_address} in {contact_list_name}")
    sesv2.create_contact(
        ContactListName=contact_list_name,
        ContactEmailAddress=email_address,
        Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'ses-v2-gs'}]
    )
    print(f"Created Contact: {email_address}")

def create_email_identity():
    email = f'test{suffix}@example.com'
    print(f"Creating Email Identity: {email}")
    sesv2.create_email_identity(EmailIdentity=email)
    sesv2.tag_resource(ResourceARN=f'arn:aws:ses:{region}:{boto3.client("sts").get_caller_identity()["Account"]}:identity/{email}', Tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'ses-v2-gs'}])
    print(f"Created Email Identity: {email}")

def clean_up():
    print("Cleaning up resources...")
    try:
        sesv2.delete_email_identity(EmailIdentity=f'test{suffix}@example.com')
        print(f"Deleted Email Identity: test{suffix}@example.com")
    except:
        pass
    try:
        sesv2.delete_contact(
            ContactListName=f'contact-list-{suffix}',
            ContactEmailAddress=f'test{suffix}@example.com'
        )
        print(f"Deleted Contact: test{suffix}@example.com")
    except:
        pass
    try:
        sesv2.delete_contact_list(ContactListName=f'contact-list-{suffix}')
        print(f"Deleted Contact List: contact-list-{suffix}")
    except:
        pass
    try:
        sesv2.delete_configuration_set(ConfigurationSetName=f'config-set-{suffix}')
        print(f"Deleted Configuration Set: config-set-{suffix}")
    except:
        pass

try:
    create_configuration_set()
    create_contact_list()
    create_contact()
    create_email_identity()
    clean_up()
    print("PASS")
except Exception as e:
    print(f"Error: {e}")
    clean_up()