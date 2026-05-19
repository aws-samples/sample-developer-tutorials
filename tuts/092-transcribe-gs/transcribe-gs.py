import boto3, json, time, os, sys

region = 'us-east-1'
suffix = str(int(time.time()))[-6:]

transcribe = boto3.client('transcribe', region_name=region)

vocabulary_name = f'tutorial-vocab-{suffix}'
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'transcribe-gs'}]

print("=== Amazon Transcribe Tutorial ===")
print("Creating a custom vocabulary to improve speech recognition accuracy.")
print()

print("=== Step 1: Create custom vocabulary ===")
print("Custom vocabularies help Transcribe recognize domain-specific terms.")
transcribe.create_vocabulary(
    VocabularyName=vocabulary_name,
    LanguageCode='en-US',
    Phrases=['AWS', 'DynamoDB', 'CloudFormation', 'Kubernetes', 'Bedrock'],
    Tags=tags
)
print(f"Vocabulary: {vocabulary_name}")

print()
print("=== Step 2: Wait for vocabulary to be ready ===")
for _ in range(20):
    time.sleep(3)
    resp = transcribe.get_vocabulary(VocabularyName=vocabulary_name)
    state = resp['VocabularyState']
    if state in ('READY', 'FAILED'):
        break
print(f"State: {state}")

print()
print("=== Step 3: List vocabularies ===")
vocabs = transcribe.list_vocabularies()
print(f"Vocabularies: {len(vocabs.get('Vocabularies', []))}")

print()
print("=== Cleanup ===")
transcribe.delete_vocabulary(VocabularyName=vocabulary_name)
print(f"Deleted: {vocabulary_name}")
print()
print("PASS")
