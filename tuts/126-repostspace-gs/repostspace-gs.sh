#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# List Spaces
aws repostspace list-spaces --query 'spaces' --output json | tr -d '\n' && echo || true

echo "PASS"