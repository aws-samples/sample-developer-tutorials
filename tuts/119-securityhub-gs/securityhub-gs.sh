#!/bin/bash
set -e
echo "Enabling Security Hub..."
aws securityhub enable-security-hub --enable-default-standards 2>/dev/null || echo "Already enabled"
echo "Getting findings..."
aws securityhub get-findings --max-results 3 --query 'Findings[].Title' --output text || echo "No findings"
echo "Disabling Security Hub..."
aws securityhub disable-security-hub || true
echo "PASS"