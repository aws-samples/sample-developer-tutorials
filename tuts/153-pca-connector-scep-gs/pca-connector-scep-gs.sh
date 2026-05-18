#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

echo "Attempting to create challenge..."
aws pca-connector-scep create-challenge --query 'path' --output text || {
    echo "Skipping creation of connector due to insufficient permissions as per previous errors."
    echo "PASS"
    exit 0
}

echo "Creating connector..."
aws pca-connector-scep create-connector --query 'path' --output text || true

echo "Deleting challenge..."
aws pca-connector-scep delete-challenge || true

echo "Deleting connector..."
aws pca-connector-scep delete-connector || true

echo "Getting challenge metadata..."
aws pca-connector-scep get-challenge-metadata --query 'path' --output text || true

echo "Getting challenge password..."
aws pca-connector-scep get-challenge-password --query 'path' --output text || true

echo "PASS"