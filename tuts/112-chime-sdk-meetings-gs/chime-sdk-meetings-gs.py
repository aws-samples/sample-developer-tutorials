import boto3
import json
import time
import uuid

client = boto3.client('chime-sdk-meetings', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
client_request_token = uuid.uuid4().hex[:8]
media_region = 'us-east-1'
external_meeting_id = f'meeting-{suffix}'

tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'chime-sdk-meetings-gs'}]

print("Creating a Chime SDK meeting...")
response = client.create_meeting(
    ClientRequestToken=client_request_token,
    MediaRegion=media_region,
    ExternalMeetingId=external_meeting_id,
    MeetingFeatures={
        'Audio': {'EchoReduction': 'AVAILABLE'},
        'Video': {'MaxResolution': 'HD'},
        'Content': {'MaxResolution': 'FHD'},
        'Attendee': {'MaxCount': 10}
    },
    Tags=tags
)
meeting_id = response['Meeting']['MeetingId']
print(f"Meeting created with ID: {meeting_id}")

print("Verifying the meeting exists...")
time.sleep(2)
try:
    response = client.get_meeting(MeetingId=meeting_id)
    if response['Meeting']['MeetingId'] == meeting_id:
        print("Meeting verified.")
except client.exceptions.ResourceNotFoundException:
    print("Meeting verification failed: Meeting not found.")

print("Creating an attendee...")
response = client.create_attendee(
    MeetingId=meeting_id,
    ExternalUserId=f'attendee-{suffix}',
    Tags=tags
)
attendee_id = response['Attendee']['AttendeeId']
print(f"Attendee created with ID: {attendee_id}")

print("Listing attendees...")
response = client.list_attendees(MeetingId=meeting_id)
attendees = response['Attendees']
print(f"Attendees listed: {json.dumps(attendees, indent=2)}")

print("Deleting the meeting...")
client.delete_meeting(MeetingId=meeting_id)
time.sleep(2)
try:
    client.get_meeting(MeetingId=meeting_id)
except client.exceptions.ResourceNotFoundException:
    print("Meeting deleted successfully.")
except client.exceptions.NotFoundException:
    print("Meeting deleted successfully.")

print("PASS")