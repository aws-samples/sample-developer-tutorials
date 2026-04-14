#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ga.log") 2>&1
export AWS_DEFAULT_REGION=us-west-2; echo "Region: us-west-2 (Global Accelerator)"
RANDOM_ID=$(openssl rand -hex 4); GA_NAME="tut-ga-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$GA_ARN" ] && { aws globalaccelerator update-accelerator --accelerator-arn "$GA_ARN" --no-enabled 2>/dev/null; sleep 5; aws globalaccelerator delete-accelerator --accelerator-arn "$GA_ARN" 2>/dev/null && echo "  Deleted accelerator"; }; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating accelerator: $GA_NAME"
GA_ARN=$(aws globalaccelerator create-accelerator --name "$GA_NAME" --query 'Accelerator.AcceleratorArn' --output text)
echo "  ARN: $GA_ARN"
echo "Step 2: Waiting for deployment..."
for i in $(seq 1 20); do STATUS=$(aws globalaccelerator describe-accelerator --accelerator-arn "$GA_ARN" --query 'Accelerator.Status' --output text); echo "  $STATUS"; [ "$STATUS" = "DEPLOYED" ] && break; sleep 10; done
echo "Step 3: Accelerator details"
aws globalaccelerator describe-accelerator --accelerator-arn "$GA_ARN" --query 'Accelerator.{Name:Name,Status:Status,DNS:DnsName,IPs:IpSets[0].IpAddresses}' --output table
echo "Step 4: Listing accelerators"
aws globalaccelerator list-accelerators --query 'Accelerators[?starts_with(Name, `tut-`)].{Name:Name,Status:Status}' --output table
echo ""; echo "Tutorial complete."
echo "Note: Global Accelerator incurs hourly charges. Clean up promptly."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
