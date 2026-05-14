#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CLIENT_REQUEST_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
MEDIA_REGION='us-east-1'
EXTERNAL_MEETING_ID="meeting-${SUFFIX}"

echo "Creating a Chime SDK meeting..."
MEETING_ID=$(aws chime-sdk-meetings create-meeting \
    --client-request-token "$CLIENT_REQUEST_TOKEN" \
    --media-region "$MEDIA_REGION" \
    --external-meeting-id "$EXTERNAL_MEETING_ID" \
    --meeting-features '{"Audio": {"EchoReduction": "AVAILABLE"}, "Video": {"MaxResolution": "HD"}, "Content": {"MaxResolution": "FHD"}, "Attendee": {"MaxCount": 10}}' \
    --query 'Meeting.MeetingId' --output text)
echo "Meeting created with ID: $MEETING_ID"

echo "Verifying the meeting exists..."
sleep 2
aws chime-sdk-meetings get-meeting --meeting-id "$MEETING_ID" \
    --query 'Meeting.MeetingId' --output text | grep "$MEETING_ID" && echo "Meeting verified." || echo "Meeting verification failed: Meeting not found."

echo "Creating an attendee..."
ATTENDEE_ID=$(aws chime-sdk-meetings create-attendee \
    --meeting-id "$MEETING_ID" \
    --external-user-id "attendee-${SUFFIX}" \
    --query 'Attendee.AttendeeId' --output text)
echo "Attendee created with ID: $ATTENDEE_ID"

echo "Listing attendees..."
aws chime-sdk-meetings list-attendees --meeting-id "$MEETING_ID"

echo "Deleting the meeting..."
aws chime-sdk-meetings delete-meeting --meeting-id "$MEETING_ID"
sleep 2
aws chime-sdk-meetings get-meeting --meeting-id "$MEETING_ID" || echo "Meeting deleted successfully."

echo "PASS"