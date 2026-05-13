import boto3
import time
import random
import string

region = 'us-east-1'
suffix = str(int(time.time())) + ''.join(random.choices(string.ascii_lowercase, k=6))
repo_name = f'test-repo-{suffix}'

codecommit = boto3.client('codecommit', region_name=region)

print("Creating repository...")
repository = codecommit.create_repository(repositoryName=repo_name)
repository_arn = repository.get('repositoryMetadata', {}).get('repositoryArn')

if repository_arn:
    print("PASS")
else:
    print("Failed to retrieve repository ARN.")

# Cleanup
try:
    codecommit.delete_repository(repositoryName=repo_name)
    print("Repository deleted.")
except Exception as e:
    print(f"Failed to delete repository: {e}")