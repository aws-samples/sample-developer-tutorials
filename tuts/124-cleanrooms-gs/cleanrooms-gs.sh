#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            collab) aws cleanrooms delete-collaboration --collaboration-identifier "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
echo "=== Creating Collaboration ==="
COLLAB_ID=$(aws cleanrooms create-collaboration --name "collab-$SUFFIX" --description "Test" --members '[]' --creator-member-abilities CAN_QUERY CAN_RECEIVE_RESULTS --creator-display-name "DocBabu" --query-log-status DISABLED --query 'collaboration.id' --output text)
echo "Collaboration: $COLLAB_ID"
CREATED_RESOURCES+=("collab:$COLLAB_ID")
echo "=== Getting Collaboration ==="
aws cleanrooms get-collaboration --collaboration-identifier "$COLLAB_ID" --query 'collaboration.name' --output text
echo "=== Tutorial Complete ==="
