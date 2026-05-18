#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
DATASTORE_NAME="store-${SUFFIX}"

# Create FHIR Datastore
DATASTORE_ID=$(aws healthlake create-fhir-datastore --datastore-type-version R4 --datastore-name "${DATASTORE_NAME}" --query 'DatastoreId' --output text)

echo "Datastore: ${DATASTORE_ID}"

# Wait for ACTIVE status
for _ in {1..20}
do
    STATUS=$(aws healthlake describe-fhir-datastore --datastore-id "${DATASTORE_ID}" --query 'DatastoreProperties.DatastoreStatus' --output text)
    if [ "${STATUS}" == "ACTIVE" ]; then 
        break
    fi
    sleep 15
done

# List FHIR Datastores
aws healthlake list-fhir-datastores --output json

# Delete FHIR Datastore
aws healthlake delete-fhir-datastore --datastore-id "${DATASTORE_ID}" || true

# Wait for DELETED status
for _ in {1..20}
do
    STATUS=$(aws healthlake describe-fhir-datastore --datastore-id "${DATASTORE_ID}" --query 'DatastoreProperties.DatastoreStatus' --output text 2>&1 || echo "DELETED")
    if [ "${STATUS}" == "DELETED" ]; then 
        break
    fi
    sleep 15
done

echo "PASS"