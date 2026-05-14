#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            var) aws frauddetector delete-variable --name "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
echo "=== Creating Variable ==="
aws frauddetector create-variable --name "var_$SUFFIX" --data-type STRING --data-source EVENT --default-value "0.0" --variable-type IP_ADDRESS
CREATED_RESOURCES+=("var:var_$SUFFIX")
echo "=== Getting Variables ==="
aws frauddetector get-variables --name "var_$SUFFIX" --query 'variables[0].name' --output text
echo "=== Tutorial Complete ==="