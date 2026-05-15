import boto3
import time

region = 'us-east-1'
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-codepipeline-role'
suffix = str(int(time.time()))[-6:]
pipeline_name = f'pipeline-{suffix}'
custom_action_name = f'custom-action-{suffix}'

client = boto3.client('codepipeline', region_name=region)

try:
    response = client.create_custom_action_type(
        category='Build',
        provider='MyCustomProvider',
        version='1',
        settings={
            'thirdPartyConfigurationUrl': 'https://example.com/config'
        },
        configurationProperties=[
            {
                'name': 'Property1',
               'required': True,
                'key': True,
               'secret': False,
                'queryable': False,
                'description': 'Property 1 description'
            },
        ],
        inputArtifactDetails={
           'minimum': 0,
           'maximum': 1
        },
        outputArtifactDetails={
           'minimum': 0,
           'maximum': 1
        },
        tags=[{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'codepipeline-gs'}]
    )
    print("Custom action created")

    response = client.create_pipeline(
        pipeline={
            'name': pipeline_name,
            'roleArn': role_arn,
           'stages': [
                {
                    'name': 'Source',
                    'actions': [
                        {
                            'name': 'SourceAction',
                            'actionTypeId': {
                                'category': 'Source',
                                'owner': 'AWS',
                                'provider': 'S3',
                               'version': '1'
                            },
                            'outputArtifacts': [
                                {
                                    'name': 'MyApp'
                                },
                            ],
                            'configuration': {
                                'S3Bucket':'my-bucket',
                                'S3ObjectKey': 'path/to/my/app.zip'
                            },
                            'runOrder': 1
                        },
                    ]
                },
                {
                    'name': 'Build',
                    'actions': [
                        {
                            'name': 'BuildAction',
                            'actionTypeId': {
                                'category': 'Build',
                                'owner': 'Custom',
                                'provider': 'MyCustomProvider',
                               'version': '1'
                            },
                            'inputArtifacts': [
                                {
                                    'name': 'MyApp'
                                },
                            ],
                            'outputArtifacts': [
                                {
                                    'name': 'BuildOutput'
                                },
                            ],
                            'configuration': {
                                'Property1': 'value1'
                            },
                            'runOrder': 1
                        },
                    ]
                }
            ]
        },
        tags=[{'key': 'project', 'value': 'doc-smith'}, {'key': 'tutorial', 'value': 'codepipeline-gs'}]
    )
    print("Pipeline created")

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    try:
        client.delete_pipeline(name=pipeline_name)
        print("Pipeline deleted")
    except:
        pass

    try:
        client.delete_custom_action_type(
            category='Build',
            provider='MyCustomProvider',
            version='1'
        )
        print("Custom action deleted")
    except:
        pass