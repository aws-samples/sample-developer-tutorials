#!/bin/bash
# Run the Python SDK scenario for this tutorial.
set -eo pipefail
cd "$(dirname "$0")"
[ ! -d ".venv" ] && python3 -m venv .venv
source .venv/bin/activate
pip install -q -r requirements.txt
echo ""
echo "$ python3 scenario_getting_started.py"
echo ""
python3 scenario_getting_started.py
