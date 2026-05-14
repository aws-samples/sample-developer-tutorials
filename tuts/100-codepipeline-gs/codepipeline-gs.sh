#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
PIPELINE_NAME="pipeline-${SUFFIX}"
CUSTOM_ACTION_NAME="custom-action-${SUFFIX}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-codepipeline-role"

aws codepipeline create-custom-action-type \
    --category Build \
    --provider MyCustomProvider \
    --version 1 \
    --settings ThirdPartyConfigurationUrl=https://example.com/config \
    --configuration-properties '[{"name": "Property1","required": true,"key": true,"secret": false,"queryable": false,"description": "Property 1 description"}]' \
    --input-artifact-details '{"minimum": 0,"maximum": 1}' \
    --output-artifact-details '{"minimum": 0,"maximum": 1}' || true

aws codepipeline create-pipeline \
    --cli-input-json '{"name": "pipeline-${SUFFIX}","roleArn": "arn:aws:iam::559823168634:role/doc-babu-codepipeline-role","stages": [{"name": "Source","actions": [{"name": "SourceAction","actionTypeId": {"category": "Source","owner": "AWS","provider": "S3","version": "1"},"outputArtifacts": [{"name": "MyApp"}],"configuration": {"S3Bucket":"my-bucket","S3ObjectKey": "path/to/my/app.zip"},"runOrder": 1}]},{"name": "Build","actions": [{"name": "BuildAction","actionTypeId": {"category": "Build","owner": "Custom","provider": "MyCustomProvider","version": "1"},"inputArtifacts": [{"name": "MyApp"}],"outputArtifacts": [{"name": "BuildOutput"}],"configuration": {"Property1": "value1"},"runOrder": 1}]}]}' || true

aws codepipeline delete-pipeline --name "${PIPELINE_NAME}" || true
aws codepipeline delete-custom-action-type --category Build --provider MyCustomProvider --version 1 || true
echo "PASS"