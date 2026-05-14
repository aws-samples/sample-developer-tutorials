#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

WORKLOAD_ID=$(aws wellarchitected create-workload --workload-name "workload-${SUFFIX}" --environment "PREPRODUCTION" --lenses "wellarchitected" --description "Test workload for review" --review-owner "test@example.com" --aws-regions "us-east-1" --query 'WorkloadId' --output text)

echo "Created workload: ${WORKLOAD_ID}"
aws wellarchitected get-workload --workload-id ${WORKLOAD_ID} --query 'Workload.WorkloadName' --output text && \
aws wellarchitected list-workloads --query 'length(WorkloadSummaries)' --output text && \
aws wellarchitected delete-workload --workload-id ${WORKLOAD_ID} --client-request-token "del-${SUFFIX}" || true && \
echo "PASS"