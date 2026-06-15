#!/bin/bash
set -e

cleanup_resources() {
  for res in "${CREATED_RESOURCES[@]}"; do
    case $res in
      "annotation-store")
        aws omics delete-annotation-store --name "${ANNOTATION_STORE_NAME}" || true
        ;;
      "annotation-store-version")
        aws omics delete-annotation-store-versions --name "${ANNOTATION_STORE_NAME}" --version-names "${ANNOTATION_STORE_VERSION}" || true
        ;;
      "configuration")
        aws omics delete-configuration --id "${CONFIGURATION_ID}" || true
        ;;
      "reference-store")
        aws omics delete-reference --id "${REFERENCE_STORE_ID}" || true
        ;;
    esac
  done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

echo "Creating an annotation store..."
ANNOTATION_STORE_NAME="tutorial-annotation-store-$SUFFIX"
ANNOTATION_STORE_ID=$(aws omics create-annotation-store --name "$ANNOTATION_STORE_NAME" --type Tsv --store-format Tsv --tags '{"Name":"AnnotationStore","Purpose":"Tutorial"}' --query 'id' --output text)
CREATED_RESOURCES+=("annotation-store")
echo "Annotation store created with ID: $ANNOTATION_STORE_ID"

echo "Creating an annotation store version..."
ANNOTATION_STORE_VERSION="version-$SUFFIX"
aws omics create-annotation-store-version --name "$ANNOTATION_STORE_NAME" --version-name "$ANNOTATION_STORE_VERSION" --tags '{"Name":"AnnotationStoreVersion","Purpose":"Tutorial"}'
CREATED_RESOURCES+=("annotation-store-version")
echo "Annotation store version created with name: $ANNOTATION_STORE_VERSION"

echo "Creating a configuration..."
CONFIGURATION_NAME="tutorial-configuration-$SUFFIX"
CONFIGURATION_ID=$(aws omics create-configuration --name "$CONFIGURATION_NAME" --tags '{"Name":"Configuration","Purpose":"Tutorial"}' --query 'id' --output text)
CREATED_RESOURCES+=("configuration")
echo "Configuration created with ID: $CONFIGURATION_ID"

echo "Creating a reference store..."
REFERENCE_STORE_NAME="tutorial-reference-store-$SUFFIX"
REFERENCE_STORE_ID=$(aws omics create-reference-store --name "$REFERENCE_STORE_NAME" --tags '{"Name":"ReferenceStore","Purpose":"Tutorial"}' --query 'id' --output text)
CREATED_RESOURCES+=("reference-store")
echo "Reference store created with ID: $REFERENCE_STORE_ID"

echo "PASS"
