# Ssm Quick Setup Tutorial

## Prerequisites

- Aws account
- Boto3 python library
- Aws credentials configured

## Steps

**1. Import libraries and set up client**

```python
import boto3, json, time
suffix = str(int(time.time()))[-6:]
client = boto3.client('ssm-quicksetup', region_name='us-east-1')
```

**2. List configuration managers**

Configuration managers define how quick setup deploys configurations.

```python
managers = client.list_configuration_managers()
print(f"Configuration managers: {len(managers.get('ConfigurationManagersList', []))}")
```

**3. Get service settings**

Service settings show the current quick setup configuration for your account.

```python
try:
    settings = client.get_service_settings()
    print(f"Explorer enabled: {settings.get('ServiceSettings', {}).get('ExplorerEnablingRoleArn', 'not set')}")
except Exception as e:
    print(f"Settings: {e}")
```

## Clean up

No resources to clean up for this tutorial.

## Next steps

To create a configuration, use `create_configuration_manager` with a configuration definition specifying the target service and parameters.