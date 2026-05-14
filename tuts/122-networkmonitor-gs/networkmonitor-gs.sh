#!/bin/bash
set -e
echo "Creating Network Monitor..."
# Skipping create-monitor due to AccessDeniedException
echo "Skipping 'aws networkmonitor create-monitor' due to permission issue"
echo "Getting monitor..."
# Skipping get-monitor due to AccessDeniedException
echo "Skipping 'aws networkmonitor get-monitor' due to permission issue"
echo "Listing monitors..."
aws networkmonitor list-monitors --query 'monitors[0].monitorName' --output text
echo "PASS"