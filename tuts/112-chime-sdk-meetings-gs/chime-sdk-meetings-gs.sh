#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
    for res in "${CREATED_RESOURCES[@]}"; do
        aws chime-sdk-meetings delete-meeting --meeting-id "$res" >>"$LOG_FILE" 2>&1
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
MEDIA_REGION='us-east-1'
EXTERNAL_MEETING_ID="meeting-${SUFFIX}"
CLIENT_REQUEST_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

echo "Creating a Chime SDK meeting..."
MEETING_RESPONSE=$(aws chime-sdk-meetings create-meeting \
    --client-request-token "$CLIENT_REQUEST_TOKEN" \
    --media-region "$MEDIA_REGION" \
    --external-meeting-id "$EXTERNAL_MEETING_ID" \
    --meeting-features '{"Audio": {"EchoReduction": "AVAILABLE"}, "Video": {"MaxResolution": "HD"}, "Content": {"MaxResolution": "FHD"}, "Attendee": {"MaxCount": 10}}' \
    --output json)
MEETING_ID=$(echo "$MEETING_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['Meeting']['MeetingId'])")
MEETING_ARN=$(echo "$MEETING_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['Meeting']['MeetingArn'])")
CREATED_RESOURCES+=("$MEETING_ID")
aws chime-sdk-meetings tag-resource --resource-arn "$MEETING_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=chime-sdk-meetings-gs
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

echo "PASS"
