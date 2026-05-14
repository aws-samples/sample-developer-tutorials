#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            domain) aws sdb delete-domain --domain-name "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
DOMAIN="test-domain-$SUFFIX"
echo "=== Creating Domain ==="
aws sdb create-domain --domain-name "$DOMAIN"
CREATED_RESOURCES+=("domain:$DOMAIN")
echo "=== Putting Attributes ==="
aws sdb put-attributes --domain-name "$DOMAIN" --item-name "item1" --attributes "Name=color,Value=red" "Name=size,Value=large"
echo "=== Getting Attributes ==="
aws sdb get-attributes --domain-name "$DOMAIN" --item-name "item1" --query 'Attributes[].Value' --output text
echo "=== Listing Domains ==="
aws sdb list-domains --query 'DomainNames' --output text
echo "=== Tutorial Complete ==="
