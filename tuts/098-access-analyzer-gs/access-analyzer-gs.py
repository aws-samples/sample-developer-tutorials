import boto3
import time

region = 'us-east-1'
suffix = str(int(time.time()))[-6:]
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-access-analyzer-role'

client = boto3.client('accessanalyzer', region_name=region)

def create_analyzer():
    print("Creating analyzer...")
    response = client.create_analyzer(
        type='ACCOUNT',
        analyzerName=f'test-analyzer-{suffix}'
    )
    analyzer_arn = response['arn']
    print(f"Analyzer created: {analyzer_arn}")
    return analyzer_arn

def create_archive_rule(analyzer_arn):
    print("Creating archive rule...")
    response = client.create_archive_rule(
        analyzerName=f'test-analyzer-{suffix}',
        ruleName=f'test-rule-{suffix}',
        filter={
           'resource': [
                {
                    'eq': [
                        'arn:aws:s3:::example-bucket'
                    ]
                },
            ]
        }
    )
    print(f"Archive rule created: {response['arn']}")

def validate_analyzer_status():
    print("Validating analyzer status...")
    response = client.list_analyzers()
    for analyzer in response['analyzers']:
        if analyzer['name'] == f'test-analyzer-{suffix}' and analyzer['status'] == 'ACTIVE':
            print("Analyzer is active")
            return
    raise Exception("Analyzer is not active")

def delete_analyzer(analyzer_arn):
    print("Deleting analyzer...")
    client.delete_analyzer(analyzerName=analyzer_arn)
    print(f"Analyzer deleted: {analyzer_arn}")

try:
    analyzer_arn = create_analyzer()
    create_archive_rule(analyzer_arn)
    validate_analyzer_status()
    delete_analyzer(analyzer_arn)
    print("PASS")
except Exception as e:
    print(f"Error: {e}")