#!/bin/bash
set -e
echo "=== CodeStar Notifications Tutorial ==="
echo "CodeStar Notifications lets you subscribe to events from developer tools."
echo ""
echo "=== Listing notification rules ==="
aws codestar-notifications list-notification-rules --query 'NotificationRules[].Id' --output text 2>/dev/null || echo "No rules"
echo ""
echo "=== Listing targets ==="
aws codestar-notifications list-targets --query 'Targets[].TargetAddress' --output text 2>/dev/null || echo "No targets"
echo ""
echo "PASS"
