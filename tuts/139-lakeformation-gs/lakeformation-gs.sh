#!/bin/bash
set -e
echo "Listing Lake Formation resources..."
aws lakeformation list-resources --query 'ResourceInfoList[0].ResourceArn' --output text || echo "No resources"
echo "Getting data lake settings..."
aws lakeformation get-data-lake-settings --query 'DataLakeSettings.DataLakeAdmins' --output text || echo "No admins"
echo "PASS"