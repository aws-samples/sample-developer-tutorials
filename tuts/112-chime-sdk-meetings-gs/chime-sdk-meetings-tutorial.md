# Chime SDK Meetings Tutorial

## Prerequisites

- Install AWS CLI and configure it with your credentials.
- Ensure Python 3 is installed on your system.

## Steps

1. **Create a temporary directory and log file**

    ```bash
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="$TEMP_DIR/log.txt"
    ```

2. **Set up resource cleanup**

    ```bash
    cleanup_resources() {
        for res in "${CREATED_RESOURCES[@]}"; do
            aws chime-sdk-meetings delete-meeting --meeting-id "$res" >>"$LOG_FILE" 2>&1
        done
        rm -rf "$TEMP_DIR"
    }

    trap cleanup_resources EXIT
    ```

3. **Generate unique identifiers**

    ```bash
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    EXTERNAL_MEETING_ID="meeting-${SUFFIX}"
    CLIENT_REQUEST_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    ```

4. **Create a Chime SDK meeting**

    ```bash
    echo "Creating a Chime SDK meeting..."
    MEETING_RESPONSE=$(aws chime-sdk-meetings create-meeting \
        --client-request-token "$CLIENT_REQUEST_TOKEN" \
        --media-region "us-east-1" \
        --external-meeting-id "$EXTERNAL_MEETING_ID" \
        --meeting-features '{"Audio": {"EchoReduction": "AVAILABLE"}, "Video": {"MaxResolution": "HD"}, "Content": {"MaxResolution": "FHD"}, "Attendee": {"MaxCount": 10}}' \
        --output json)
    MEETING_ID=$(echo "$MEETING_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['Meeting']['MeetingId'])")
    MEETING_ARN=$(echo "$MEETING_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['Meeting']['MeetingArn'])")
    CREATED_RESOURCES+=("$MEETING_ID")
    aws chime-sdk-meetings tag-resource --resource-arn "$MEETING_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=chime-sdk-meetings-gs
    echo "Meeting created with ID: $MEETING_ID"
    ```

5. **Verify the meeting exists**

    ```bash
    echo "Verifying the meeting exists..."
    sleep 2
    aws chime-sdk-meetings get-meeting --meeting-id "$MEETING_ID" \
        --query 'Meeting.MeetingId' --output text | grep "$MEETING_ID" && echo "Meeting verified." || echo "Meeting verification failed: Meeting not found."
    ```

6. **Create an attendee**

    ```bash
    echo "Creating an attendee..."
    ATTENDEE_ID=$(aws chime-sdk-meetings create-attendee \
        --meeting-id "$MEETING_ID" \
        --external-user-id "attendee-${SUFFIX}" \
        --query 'Attendee.AttendeeId' --output text)
    echo "Attendee created with ID: $ATTENDEE_ID"
    ```

7. **List attendees**

    ```bash
    echo "Listing attendees..."
    aws chime-sdk-meetings list-attendees --meeting-id "$MEETING_ID"
    ```

## Clean up

All created resources are automatically cleaned up at the end of the script.

## Next steps

- Explore additional Chime SDK features.
- Integrate Chime SDK into your applications.
