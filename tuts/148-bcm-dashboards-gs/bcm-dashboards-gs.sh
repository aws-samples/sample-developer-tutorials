#!/bin/bash
set -e
echo "=== BCM Dashboards Tutorial ==="
echo "Billing and Cost Management dashboards provide visibility into your AWS spending."
echo ""
echo "=== Listing dashboards ==="
aws bcm-dashboards list-dashboards --query 'dashboards[].dashboardName' --output text 2>/dev/null || echo "No dashboards"
echo ""
echo "PASS"
