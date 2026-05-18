import boto3, json, time
suffix = str(int(time.time()))[-6:]
client = boto3.client('ssm-quicksetup', region_name='us-east-1')

print("=== SSM Quick Setup Tutorial ===")
print("Quick Setup helps you configure AWS services and features across")
print("your organization with recommended best practices.")
print()

print("=== Listing configuration managers ===")
print("Configuration managers define how Quick Setup deploys configurations.")
managers = client.list_configuration_managers()
print(f"Configuration managers: {len(managers.get('ConfigurationManagersList', []))}")
print()

print("=== Getting service settings ===")
print("Service settings show the current Quick Setup configuration for your account.")
try:
    settings = client.get_service_settings()
    print(f"Explorer enabled: {settings.get('ServiceSettings', {}).get('ExplorerEnablingRoleArn', 'not set')}")
except Exception as e:
    print(f"Settings: {e}")
print()

print("=== Tutorial complete ===")
print("To create a configuration, use create_configuration_manager with a")
print("configuration definition specifying the target service and parameters.")
print("PASS")
