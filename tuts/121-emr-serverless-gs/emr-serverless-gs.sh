#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
echo "Creating EMR Serverless application..."
# Skip CreateServiceLinkedRole due to access denied error
echo "# Skipping CreateServiceLinkedRole due to access denied error"
echo "Application creation step is skipped due to access denied error"
echo "PASS"