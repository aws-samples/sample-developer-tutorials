#!/bin/bash
set -e

# Title Banner
echo "=== AWS CodeArtifact Tutorial ==="
echo "This tutorial demonstrates how to create and manage resources in AWS CodeArtifact."
echo "We will create a temporary domain and repository, and then clean up the resources at the end."
echo ""

# Logging setup
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/tutorial.log"
if [ -t 1 ]; then 
# Generate a random suffix for unique resource names
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            repo) 
                echo "=== Cleaning up repository: $id ==="
                aws codeartifact delete-repository --domain "dom$SUFFIX" --repository "$id" 2>/dev/null || true
                ;;
            domain) 
                echo "=== Cleaning up domain: $id ==="
                aws codeartifact delete-domain --domain "$id" 2>/dev/null || true
                ;;
        esac
    done
    echo "=== Removing temporary directory: $TEMP_DIR ==="
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Step 1: Create a Temporary Domain ==="
echo "Creating a temporary domain is essential for organizing and managing your CodeArtifact repositories."
echo "Each domain can contain multiple repositories, and domains help in applying policies and permissions."
DOMAIN_NAME="dom$SUFFIX"
aws codeartifact create-domain --domain "$DOMAIN_NAME"
echo "Result: Domain $DOMAIN_NAME created"
CREATED_RESOURCES+=("domain:$DOMAIN_NAME")
echo ""

echo "=== Step 2: Create a Temporary Repository ==="
echo "Repositories within a domain store your package versions. Creating a repository allows you to upload and manage packages."
REPO_NAME="repo$SUFFIX"
aws codeartifact create-repository --domain "$DOMAIN_NAME" --repository "$REPO_NAME"
echo "Result: Repository $REPO_NAME created in domain $DOMAIN_NAME"
CREATED_RESOURCES+=("repo:$REPO_NAME")
echo ""

echo "=== Tutorial Complete ==="
echo "In this tutorial, you learned how to:"
echo "1. Create a temporary domain in AWS CodeArtifact."
echo "2. Create a temporary repository within that domain."
echo "All created resources have been automatically cleaned up to avoid unnecessary charges."
fi