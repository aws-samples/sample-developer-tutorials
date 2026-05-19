import boto3
import time
import random

region = 'us-east-1'
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-transcribe-role'
suffix = str(int(time.time()))[-6:] + str(random.randint(100, 999))

transcribe = boto3.client('transcribe', region_name=region)
s3 = boto3.client('s3', region_name=region)

vocabulary_name = f'CustomVocabulary{suffix}'
vocabulary_file_key = f'/test-files/your-vocabulary-file.txt'
vocabulary_bucket = 'your-bucket-name'  # Replace with your actual S3 bucket name
vocabulary_file_uri = f's3://{vocabulary_bucket}{vocabulary_file_key}'

tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'transcribe-gs'}]

try:
    print("Uploading vocabulary file to S3...")
    s3.upload_file(f'..{vocabulary_file_key}', vocabulary_bucket, vocabulary_file_key[1:])

    print("Creating custom vocabulary...")
    vocabulary_response = transcribe.create_vocabulary(
        VocabularyName=vocabulary_name,
        LanguageCode='en-US',
        VocabularyFileUri=vocabulary_file_uri,
        Tags=tags
    )

    print("Waiting for vocabulary to be ready...")
    while True:
        vocabulary_info = transcribe.get_vocabulary(VocabularyName=vocabulary_name)
        if vocabulary_info['VocabularyState'] == 'READY':
            break
        time.sleep(5)

    print("Custom vocabulary created and ready.")

    print("Deleting custom vocabulary...")
    transcribe.delete_vocabulary(VocabularyName=vocabulary_name)
    print("Custom vocabulary deleted.")

except Exception as e:
    print(f"An error occurred: {e}")

print("PASS")