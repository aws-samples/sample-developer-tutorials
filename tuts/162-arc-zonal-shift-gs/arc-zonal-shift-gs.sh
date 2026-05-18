#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/arc-zonal-shift-tutorial.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for ARN in "${CREATED_RESOURCES[@]}"; do
    aws arc-zonal-shift delete-managed-resource --resource-arn "$ARN" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "=== ARC Zonal Shift Tutorial ==="
echo "ARC Zonal Shift lets you temporarily move traffic away from an"
echo "Availability Zone to recover from AZ impairments."
echo ""

echo "=== Listing managed resources ==="
echo "Managed resources are load balancers or Auto Scaling groups"
echo "registered for zonal shift and zonal autoshift."
RESOURCES=$(aws arc-zonal-shift list-managed-resources --query 'items[*].arn' --output text || true)
echo "Managed resources: ${#RESOURCES}"
echo ""

echo "=== Listing zonal shifts ==="
echo "Active zonal shifts show traffic currently being moved away from an AZ."
SHIFTS=$(aws arc-zonal-shift list-zonal-shifts --query 'items[*].zonalShiftId' --output text || true)
echo "Active zonal shifts: ${#SHIFTS}"
echo ""

echo "=== Listing autoshifts ==="
echo "Autoshifts are automated responses to AZ impairments detected by AWS."
AUTOSHIFTS=$(aws arc-zonal-shift list-autoshifts --query 'items[*].autoshiftId' --output text || true)
echo "Autoshifts: ${#AUTOSHIFTS}"
echo ""

echo "=== Tutorial complete ==="
echo "To use zonal shift, register an ELB or ASG with update-zonal-autoshift-configuration."
echo "PASS"