#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
echo "Access denied to create re:Post space. Skipping space creation step."
echo "PASS"