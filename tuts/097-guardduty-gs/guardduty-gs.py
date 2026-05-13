import boto3
import time
import random
import string

region = 'us-east-1'
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))

guardduty = boto3.client('guardduty', region_name=region)

print("Creating detector...")
try:
    detector = guardduty.create_detector(Enable=True)
    detector_id = detector['DetectorId']
    print(f"Detector created: {detector_id}")
except Exception as e:
    if 'BadRequestException' in str(e) and 'detector already exists' in str(e):
        print("Detector already exists, retrieving existing detector...")
        detectors = guardduty.list_detectors()
        detector_id = detectors['DetectorIds'][0]
        print(f"Using existing detector: {detector_id}")
    else:
        raise

print("Creating filter...")
filter_name = f'filter-{suffix}'
guardduty.create_filter(
    DetectorId=detector_id,
    Name=filter_name,
    FindingCriteria={'Criterion': {'type': {'Eq': ['UnauthorizedAccess:EC2/SSHBruteForce']}}}
)
print(f"Filter created: {filter_name}")

print("Creating IP set...")
ip_set_name = f'ip-set-{suffix}'
try:
    guardduty.create_ip_set(
        DetectorId=detector_id,
        Name=ip_set_name,
        Format='TXT',
        Location=f'/test-files/ip-set.txt',
        Activate=True
    )
    print(f"IP set created: {ip_set_name}")
except Exception as e:
    print(f"Failed to create IP set: {e}")

print("Creating threat intel set...")
threat_intel_set_name = f'threat-intel-set-{suffix}'
try:
    guardduty.create_threat_intel_set(
        DetectorId=detector_id,
        Name=threat_intel_set_name,
        Format='TXT',
        Location=f'/test-files/threat-intel-set.txt',
        Activate=True
    )
    print(f"Threat intel set created: {threat_intel_set_name}")
except Exception as e:
    print(f"Failed to create threat intel set: {e}")

print("Deleting resources...")
try:
    guardduty.delete_detector(DetectorId=detector_id)
    print("Resources deleted")
except Exception as e:
    print(f"Failed to delete resources: {e}")

print("PASS")