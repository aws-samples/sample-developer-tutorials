import boto3
import json
import time

client = boto3.client('serverlessrepo', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]

# Create Application
response = client.create_application(
    Author='doc-smith',
    Description='Sample application for serverlessrepo tutorial',
    Name=f'doc-smith-app-{suffix}',
    Labels=['project:doc-smith', 'tutorial:serverlessrepo-gs']
)
application_id = response['ApplicationId']
print(f"Application created: {application_id}")

# Verify Application
response = client.get_application(
    ApplicationId=application_id
)
print(f"Application verified: {response['Name']}")

# Create CloudFormation Template
template_body = json.dumps({
    "Transform": "AWS::Serverless-2016-10-31",
    "Resources": {
        "SampleResource": {
            "Type": "AWS::S3::Bucket",
            "Properties": {
                "BucketName": f"doc-smith-bucket-{suffix}"
            }
        }
    }
})

# Create Application Version with Template Specification
version = f"1.0.{suffix}"
response = client.create_application_version(
    ApplicationId=application_id,
    SemanticVersion=version,
    TemplateBody=template_body
)
print(f"Application version created: {version}")

# Clean up
try:
    client.delete_application(
        ApplicationId=application_id
    )
    print(f"Application deleted: {application_id}")
except Exception as e:
    print(f"Failed to delete application: {e}")

print("PASS")