import boto3
import time

region = 'us-east-1'
suffix = str(int(time.time()))[-6:]
domain_name = f'domain-{suffix}'
repo_name = f'repo-{suffix}'
package_group_name = f'package-group-{suffix}'
import os, sys
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN') or (sys.argv[1] if len(sys.argv) > 1 else None)
if not ROLE_ARN:
    print('Usage: python3 script.py <role-arn>')
    print('Or set TUTORIAL_ROLE_ARN environment variable')
    print('Create the role with: aws cloudformation deploy --template-file prereqs.yaml --stack-name tutorial-prereqs --capabilities CAPABILITY_NAMED_IAM')
    sys.exit(1)

client = boto3.client('codeartifact', region_name=region)

try:
    print("Creating domain...")
    domain = client.create_domain(domain=domain_name, tags=[{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'codeartifact-gs'}])
    print(f"Domain created: {domain_name}")

    print("Creating repository...")
    repository = client.create_repository(
        domain=domain_name,
        repository=repo_name,
        externalConnections=['public:pypi'],
        tags=[{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'codeartifact-gs'}]
    )
    print(f"Repository created: {repo_name}")

    print("Creating package group...")
    package_group = client.create_package_group(
        domain=domain_name,
        packageGroup=package_group_name,
        contactInfo='test@example.com',
        description='Test package group',
        tags=[{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'codeartifact-gs'}]
    )
    print(f"Package group created: {package_group_name}")

    print("Associating external connection...")
    client.associate_external_connection(
        domain=domain_name,
        repository=repo_name,
        externalConnection='public:pypi'
    )
    print("External connection associated")

    print("Copying package versions...")
    client.copy_package_versions(
        domain=domain_name,
        repository=repo_name,
        format='pypi',
        package='sample-package',
        versions=['1.0.0'],
        targetRepository=repo_name
    )
    print("Package versions copied")

    print("Deleting package group...")
    client.delete_package_group(
        domain=domain_name,
        packageGroup=package_group_name
    )
    print(f"Package group deleted: {package_group_name}")

    print("Deleting repository...")
    client.delete_repository(
        domain=domain_name,
        repository=repo_name
    )
    print(f"Repository deleted: {repo_name}")

    print("Deleting domain...")
    client.delete_domain(domain=domain_name)
    print(f"Domain deleted: {domain_name}")

    print("PASS")
except Exception as e:
    print(f"Error: {e}")