#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/codedeploy.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); APP_NAME="tut-app-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws deploy delete-application --application-name "$APP_NAME" 2>/dev/null && echo "  Deleted app"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating application: $APP_NAME"
aws deploy create-application --application-name "$APP_NAME" --compute-platform Server --query 'applicationId' --output text
echo "Step 2: Listing applications"
aws deploy list-applications --query 'applications[?starts_with(@, `tut-`)]' --output table
echo "Step 3: Getting application details"
aws deploy get-application --application-name "$APP_NAME" --query 'application.{Name:applicationName,Id:applicationId,Created:createTime}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
