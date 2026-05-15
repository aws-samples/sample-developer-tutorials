#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            app) aws resiliencehub delete-app --app-arn "$id" --force-delete 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
echo "=== Creating App ==="
APP_ARN=$(aws resiliencehub create-app --name "app-$SUFFIX" --tags '{"project": "doc-smith", "tutorial": "resiliencehub-gs"}' --query 'app.appArn' --output text)
echo "App: $APP_ARN"
CREATED_RESOURCES+=("app:$APP_ARN")
echo "=== Describing App ==="
aws resiliencehub describe-app --app-arn "$APP_ARN" --query 'app.name' --output text
echo "=== Listing Apps ==="
aws resiliencehub list-apps --query 'appSummaries[].name' --output text
echo "=== Tutorial Complete ==="
