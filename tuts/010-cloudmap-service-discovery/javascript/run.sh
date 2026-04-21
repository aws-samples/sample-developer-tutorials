#!/bin/bash
# Run the JavaScript SDK v3 scenario for this tutorial.
set -eo pipefail
cd "$(dirname "$0")"
[ ! -d "node_modules" ] && npm install --quiet
echo ""
echo "$ node scenarios/getting-started.js"
echo ""
node scenarios/getting-started.js
